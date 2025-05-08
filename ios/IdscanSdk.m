#import <React/RCTRootView.h>
#import "IdscanSdk.h"
#import "ScannerViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "react_native_idscan_sdk-Swift.h"

@implementation IdscanSdk

// Constants
const NSString* typeCombined = @"combined";
const NSString* typeMRZ = @"mrz";
const NSString* typePDF = @"pdf";

RCT_EXPORT_MODULE()
RCT_EXPORT_METHOD(scan:(NSString *)type apiKeys: (NSDictionary *)apiKeys callback:(RCTResponseSenderBlock)callback)
{
    self.scannerCallback = callback;
    self.scannerType = type;
    self.scannerPDFKey = apiKeys[@"iosDetectorPDFLicenseKey"];
    self.scannerMRZKey = apiKeys[@"iosDetectorMRZLicenseKey"];
    self.parserKey = apiKeys[@"iosParserPDFLicenseKey"];

    // Store camera and parser keys
    [[NSUserDefaults standardUserDefaults] setValue: type forKey:@"scannerType"];
    [[NSUserDefaults standardUserDefaults] setValue: self.scannerPDFKey forKey:@"scannerPDFKey"];
    [[NSUserDefaults standardUserDefaults] setValue: self.scannerMRZKey forKey:@"scannerMRZKey"];
    [[NSUserDefaults standardUserDefaults] setValue: self.parserKey forKey:@"parserKey"];
    [[NSUserDefaults standardUserDefaults] synchronize];

    dispatch_async(dispatch_get_main_queue(), ^(void) {
        ScannerViewController *scannerViewController = [[ScannerViewController alloc] init];
        scannerViewController.delegate = self;
        NSLog(@"IDScanner: Starting camera scanner...");
        
        UIWindow *windowRoot = nil;
        NSArray *windows = [[UIApplication sharedApplication] windows];
        for (UIWindow *window in windows) {
            if (window.isKeyWindow) {
                windowRoot = window;
                break;
            }
        }
        
        UIViewController *rootViewController = [windowRoot rootViewController];
        [rootViewController presentViewController:scannerViewController animated:YES completion:nil];
    });
}

- (void)returnScanResult:(ScannerViewController *)controller scanResult:(NSString *)result {
    NSLog(@"IDScanner: Raw scan result: %@", result);
    NSMutableDictionary *formattedData = [NSMutableDictionary dictionary];

    if (result != nil) {
        // initialize parser
        IDScanIDParser *parser = [IDScanIDParser new];
        BOOL isLicensed = [parser setLicense:self.parserKey];
      
        // check if licensed
        if (!isLicensed) {
            NSLog(@"IDScanner: Failed to set license for IDScanIDParser. Key: %@", self.parserKey);
            [formattedData setObject: @(false) forKey: @"success"];
            [formattedData setObject: [NSNull null] forKey: @"data"];
            self.scannerCallback(@[@"Parser license error", formattedData]);
            return;
        }

        // parse regardless of scanner type since it's already combined
        NSDictionary<NSString *, NSString *> *parsedData = [parser parse:result];

        if (parsedData != nil) {
          [formattedData setObject: @(true) forKey: @"success"];
          [formattedData setObject: parsedData forKey: @"data"];

          self.scannerCallback(@[[NSNull null], formattedData]);
        } else {
          [formattedData setObject: @(false) forKey: @"success"];
          [formattedData setObject: [NSNull null] forKey: @"data"];

          self.scannerCallback(@[@"Invalid Drivers License", formattedData]);
        }
    } else {
        [formattedData setObject: @(false) forKey: @"success"];
        [formattedData setObject: [NSNull null] forKey: @"data"];

        self.scannerCallback(@[[NSNull null], formattedData]);
    }
}

- (NSDictionary *)constantsToExport
{
 return @{
     @"TYPE_COMBINED": typeCombined,
     @"TYPE_MRZ": typeMRZ,
     @"TYPE_PDF": typePDF
 };
}

+ (BOOL)requiresMainQueueSetup
{
  return YES;
}

@end
