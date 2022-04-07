//
//  IDScanMRZParser.h
//  IDScanMRZParser
//
//  Created by Alex S. on 21/02/2019.
//  Copyright © 2019 Abycus. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IDScanMRZParser : NSObject

@property (copy, nonatomic, readonly) NSString *version;

- (NSDictionary<NSString *, NSString *> *)parse:(NSString *)rawString;

@end
