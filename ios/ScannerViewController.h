//
//  DriverLicense.h
//  CodeLib
//
//  Created by Александр Ушаков on 15/05/14.
//  Copyright (c) 2014 Александр Ушаков. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <CoreVideo/CoreVideo.h>
#import <CoreMedia/CoreMedia.h>

typedef enum eMainScreenState {
	NORMAL,
	LAUNCHING_CAMERA,
	CAMERA,
	CAMERA_DECODING,
	DECODE_DISPLAY,
	CANCELLING
} MainScreenState;

#define DecoderResultNotification @"DecoderResultNotification"

@interface DecoderResult : NSObject {
	BOOL succeeded;
	NSString *result;
}

@property (nonatomic, assign) BOOL succeeded;
@property (nonatomic, retain) NSString *result;

+(DecoderResult *)createSuccess:(NSString *)result;
+(DecoderResult *)createFailure;

@end

// Define the delegate protocol so we can send results back to the caller
@class ScannerViewController;
@protocol ScannerViewControllerDelegate <NSObject>
- (void)returnScanResult:(ScannerViewController *)controller scanResult:(NSString *)result;
@end

@interface ScannerViewController : UIViewController <AVCaptureVideoDataOutputSampleBufferDelegate, UIAlertViewDelegate>

@property (nonatomic, weak) id <ScannerViewControllerDelegate> delegate;

@property (nonatomic, assign) MainScreenState state;
@property (weak, nonatomic) IBOutlet UIButton *btn;
@property (weak, nonatomic) IBOutlet UILabel *demoLbl;

- (IBAction)closeBtn:(id)sender;
@property (nonatomic, retain) AVCaptureSession *captureSession;
@property (nonatomic, retain) AVCaptureVideoPreviewLayer *prevLayer;
@property (nonatomic, retain) AVCaptureDevice *device;
@property (nonatomic, retain) NSTimer *focusTimer;

- (void)decodeResultNotification: (NSNotification *)notification;
- (void)initCapture;
- (void) startScanning;
- (void) stopScanning;
- (void) toggleTorch;
@end
