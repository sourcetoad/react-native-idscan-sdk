//
//  IDScanPDFParser.h
//  IDScanPDFParser
//
//  Created by Ossir on 14.07.2020.
//

#import <Foundation/Foundation.h>

@interface IDScanPDFParser : NSObject

@property (copy, nonatomic, readonly) NSString *version;
@property (copy, nonatomic) NSString *activationKey;

+ (instancetype)parserWithActivationKey:(NSString *)activationKey;
- (instancetype)initWithActivationKey:(NSString *)activationKey;

- (NSDictionary<NSString *, NSString *> *)parse:(NSString *)rawString;

@end

