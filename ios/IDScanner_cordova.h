#import <Cordova/CDVPlugin.h>
#import "ScannerViewController.h"

@interface IDScanner : CDVPlugin <ScannerViewControllerDelegate>
{
	NSString* callbackId;
	NSString* cameraKey;
	NSString* parserKey;
}

@property (nonatomic, copy) NSString* callbackId;
@property (nonatomic, copy) NSString* cameraKey;
@property (nonatomic, copy) NSString* parserKey;

- (void)scan:(CDVInvokedUrlCommand*)command;

@end
