#import "IdscanSdk.h"

@implementation IdscanSdk

RCT_EXPORT_MODULE()

// TODO: trigger license scanner
RCT_EXPORT_METHOD(scan:(NSString *)cameraKey parserKey:(NSString *)parserKey callback:(RCTResponseSenderBlock)callback)
{
  NSDictionary *someData = [NSDictionary dictionary];
  callback(@[[NSNull null], someData]); // (error, someData) in js
}

@end
