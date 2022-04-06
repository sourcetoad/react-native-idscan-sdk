#import "IDScanner.h"
#import "ScannerViewController.h"
#import <idscanParser/idscanParser.h>
#import <Cordova/CDV.h>
#import <AVFoundation/AVFoundation.h>

@implementation IDScanner
@synthesize callbackId;
@synthesize cameraKey;
@synthesize parserKey;
/*
- (CDVPlugin*) initWithWebView:(UIWebView*)theWebView
{
    self = (IDScannerPlugin*)[super initWithWebView:theWebView];
    return self;
}
*/
- (void)scan:(CDVInvokedUrlCommand*)command
{
    self.cameraKey = [command.arguments objectAtIndex:0];    
    self.parserKey = [command.arguments objectAtIndex:1];    
    self.callbackId = command.callbackId;

    // BarcodeScanner sdk and DriverLicenseParser sdk require these activation codes
    NSLog(@"IDScanner: cameraKey=%@",self.cameraKey);
    NSLog(@"IDScanner: parserKey=%@",self.parserKey);
    [[NSUserDefaults standardUserDefaults] setValue:self.cameraKey forKey:@"cameraKey"];
    [[NSUserDefaults standardUserDefaults] setValue:self.parserKey forKey:@"DriverLicenseParserCurrentSerial"];
    [[NSUserDefaults standardUserDefaults] synchronize];

    // create scanner controller, set our plugin as a delegate so it can call us with the result.
    ScannerViewController* scannerViewController = [[ScannerViewController alloc] init];
    scannerViewController.delegate = self;
    NSLog(@"IDScanner: Starting camera scanner...");
    [self.viewController presentViewController:scannerViewController animated:YES completion:nil];
}

- (void)returnScanResult:(ScannerViewController *)controller scanResult:(NSString *)scanResult
{
    CDVPluginResult* pluginResult = nil;

    if (scanResult != nil){
        NSLog(@"IDScanner: Raw scan was returned from camera scanner: %@",scanResult);
        NSLog(@"IDScanner: Calling DriverLicenseParser library...");
        DriverLicense *dl = [[DriverLicense alloc] init];
        if ([dl parseDLString:scanResult hideSerialAlert:NO] == NO){
            NSLog(@"IDScanner ERROR: DriverLicenseParser returned nothing");
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"DriverLicenseParser error parsing scanned input"];
        }else{
            AudioServicesPlayAlertSoundWithCompletion(kSystemSoundID_Vibrate,nil);
            NSLog(@"IDScanner: DriverLicenseParser success, fullName from DL=%@",dl.fullName);
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:[dl fields]];
        }
    }else{
        NSLog(@"IDScanner: Camera scan was cancelled or returned nil");
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Camera scan was cancelled or returned nil"];
    }
            
    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackId];
}

@end
