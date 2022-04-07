#import <React/RCTRootView.h>
#import "IdscanSdk.h"
#import "ScannerViewController.h"

@implementation IdscanSdk

RCT_EXPORT_MODULE()

// TODO: trigger license scanner
RCT_EXPORT_METHOD(scan:(NSString *)cameraKey parserKey:(NSString *)parserKey callback:(RCTResponseSenderBlock)callback)
{
    self.scannerCallback = callback;
    
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        ScannerViewController* scannerViewController = [[ScannerViewController alloc] init];
        scannerViewController.delegate = self;
        NSLog(@"IDScanner: Starting camera scanner...");
        
        UIViewController *rootViewController = [[[UIApplication sharedApplication] keyWindow] rootViewController];
        
        [rootViewController presentViewController:scannerViewController animated:YES completion:nil];
    });
}

- (void)returnScanResult:(ScannerViewController *)controller scanResult:(NSString *)result {
    NSLog(@"IDScanner: Raw scan was returned from camera scanner: %@", result);
    NSMutableDictionary *formattedData = [NSMutableDictionary dictionary];
    
    if (result != nil) {
        [formattedData setObject: @"true" forKey: @"success"];
        [formattedData setObject: result forKey: @"data"];
    } else {
        [formattedData setObject: @"false" forKey: @"success"];
        [formattedData setObject: [NSNull null] forKey: @"data"];
    }

    self.scannerCallback(@[[NSNull null], formattedData]); // (error, someData) in js
}

@end
