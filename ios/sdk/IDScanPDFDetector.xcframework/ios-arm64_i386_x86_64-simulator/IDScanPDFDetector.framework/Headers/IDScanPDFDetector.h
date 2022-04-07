//
//  IDScanPDFDetector.h
//  IDScanPDFDetector
//

#import <CoreImage/CIImage.h>
#import <CoreMedia/CMSampleBuffer.h>

@interface IDScanPDFDetector : NSObject

@property (copy, nonatomic, readonly) NSString *version;
@property (copy, nonatomic) NSString *activationKey;

+ (instancetype)detectorWithActivationKey:(NSString *)activationKey;
- (instancetype)initWithActivationKey:(NSString *)activationKey;

- (NSDictionary *)detectFromImage:(CIImage *)image;
- (NSDictionary *)detectFromSampleBuffer:(CMSampleBufferRef)sampleBuffer;

@end


