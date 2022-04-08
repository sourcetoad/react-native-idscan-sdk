#import <React/RCTBridgeModule.h>
#import "ScannerViewController.h"

@interface IdscanSdk: NSObject <RCTBridgeModule, ScannerViewControllerDelegate>

@property (nonatomic, copy) RCTResponseSenderBlock scannerCallback;
@property (nonatomic, copy) NSString* scannerType;
@property (nonatomic, copy) NSString* scannerPDFKey;
@property (nonatomic, copy) NSString* scannerMRZKey;
@property (nonatomic, copy) NSString* parserKey;

@end
