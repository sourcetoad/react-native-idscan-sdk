#import <React/RCTBridgeModule.h>
#import "ScannerViewController.h"

@interface IdscanSdk : NSObject <RCTBridgeModule, ScannerViewControllerDelegate>

@property (nonatomic, copy) RCTResponseSenderBlock scannerCallback;
@property (nonatomic, copy) NSString* cameraKey;
@property (nonatomic, copy) NSString* parserKey;

@end
