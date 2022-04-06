//
//  MRZDetection.h
//  MRZDetection
//
//  Created by Дмитрий Грищенко on 22/02/2019.
//  Copyright © 2019 Abycus. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Barcode2DScanner : NSObject

- (void) registerCode: (NSString*) code;
- (void) registerMRZKey: (NSString*) key;
- (NSString*) scanGrayscaleImage: (uint8_t*)pp_image Width: (int) width Height: (int) height;
- (NSString*) detectMRZ: (unsigned char*)pp_image width:(int)width height:(int)height;
- (NSString*) getVersion;

@end
