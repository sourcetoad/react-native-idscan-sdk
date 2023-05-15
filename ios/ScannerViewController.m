#include <mach/mach_host.h>
#import "ScannerViewController.h"

// IDScan Libraries
@import IDScanPDFDetector;
@import IDScanMRZDetector;

@implementation ScannerViewController {
    AVCaptureSession *_captureSession;
    AVCaptureDevice *_device;
    AVCaptureVideoPreviewLayer *_prevLayer;
    bool running;
    NSString *lastFormat;
    MainScreenState state;
    CGImageRef decodeImage;
    NSString *decodeResult;
    size_t width;
    size_t height;
    size_t bytesPerRow;
    unsigned char *baseAddress;
    NSTimer *focusTimer;
}

@synthesize captureSession = _captureSession;
@synthesize prevLayer = _prevLayer;
@synthesize device = _device;
@synthesize state;
@synthesize focusTimer;
@synthesize delegate;

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

#if TARGET_IPHONE_SIMULATOR
    NSLog(@"IDScanner: On iOS simulator camera is not supported");
    [self.delegate returnScanResult:self scanResult:nil];
    [self dismissViewControllerAnimated:YES completion:nil];
#else
    [self initCapture];
#endif
    [self startScanning];
}

- (void)viewWillDisappear:(BOOL) animated {
    [super viewWillDisappear:animated];
    [self stopScanning];
    [self deinitCapture];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.prevLayer = nil;
    [[NSNotificationCenter defaultCenter] addObserver: self selector:@selector(decodeResultNotification:) name: DecoderResultNotification object: nil];
}

// IOS 7 statusbar hide
- (BOOL)prefersStatusBarHidden
{
    return YES;
}

-(void) reFocus {
    NSError *error;
    if ([self.device lockForConfiguration:&error]) {
        if ([self.device isFocusPointOfInterestSupported]) {
            [self.device setFocusPointOfInterest:CGPointMake(0.49,0.49)];
            [self.device setFocusMode:AVCaptureFocusModeAutoFocus];
        }
        [self.device unlockForConfiguration];
    }
}

- (void)toggleTorch
{
    if ([self.device isTorchModeSupported:AVCaptureTorchModeOn]) {
        NSError *error;

        if ([self.device lockForConfiguration:&error]) {
            if ([self.device torchMode] == AVCaptureTorchModeOn)
                [self.device setTorchMode:AVCaptureTorchModeOff];
            else
                [self.device setTorchMode:AVCaptureTorchModeOn];

            if ([self.device isFocusModeSupported: AVCaptureFocusModeContinuousAutoFocus])
                self.device.focusMode = AVCaptureFocusModeContinuousAutoFocus;

            [self.device unlockForConfiguration];
        }
    }
}

- (void)initCapture
{
    NSMutableArray *deviceTypes = [NSMutableArray array];

    if (@available(iOS 13.0, *)) {
        [deviceTypes addObject:AVCaptureDeviceTypeBuiltInTripleCamera];
        [deviceTypes addObject:AVCaptureDeviceTypeBuiltInDualWideCamera];
        [deviceTypes addObject:AVCaptureDeviceTypeBuiltInUltraWideCamera];
    }

    if(@available(iOS 11.1, *)) {
        [deviceTypes addObject:AVCaptureDeviceTypeBuiltInTrueDepthCamera];
    }

    if(@available(iOS 10.2, *)) {
        [deviceTypes addObject:AVCaptureDeviceTypeBuiltInDualCamera];
    }

    if(@available(iOS 10.0, *)) {
        [deviceTypes addObject:AVCaptureDeviceTypeBuiltInTelephotoCamera];
        [deviceTypes addObject:AVCaptureDeviceTypeBuiltInWideAngleCamera];
    }

    AVCaptureDeviceDiscoverySession *captureDeviceDiscoverySession = [AVCaptureDeviceDiscoverySession
                                                                      discoverySessionWithDeviceTypes:deviceTypes
                                                                      mediaType:AVMediaTypeVideo
                                                                      position:AVCaptureDevicePositionBack];

    NSArray *captureDevices = [captureDeviceDiscoverySession devices];
    if (captureDevices.count > 0) {
        self.device = captureDevices[0];
    } else {
        self.device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    }

    AVCaptureDeviceInput *captureInput = [AVCaptureDeviceInput deviceInputWithDevice:self.device error:nil];
    AVCaptureVideoDataOutput *captureOutput = [[AVCaptureVideoDataOutput alloc] init];
    captureOutput.alwaysDiscardsLateVideoFrames = YES;
    [captureOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];

    // Set the video output to store frame in BGRA (It is supposed to be faster)
    NSString* key = (NSString*)kCVPixelBufferPixelFormatTypeKey;

    // Set the video output to store frame in 422YpCbCr8(It is supposed to be faster)
    NSNumber* value = [NSNumber numberWithUnsignedInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange];
    NSDictionary* videoSettings = [NSDictionary dictionaryWithObject:value forKey:key];
    [captureOutput setVideoSettings:videoSettings];

    // Create a capture session
    self.captureSession = [[AVCaptureSession alloc] init];

    // We add input and output
    [self.captureSession addInput:captureInput];
    [self.captureSession addOutput:captureOutput];

    if ([self.captureSession canSetSessionPreset:AVCaptureSessionPreset1280x720]) {
        NSLog(@"Set preview port to 1280X720");
        self.captureSession.sessionPreset = AVCaptureSessionPreset1280x720;
    } else
        // Set to 640x480 if 1280x720 not supported on device
        if ([self.captureSession canSetSessionPreset:AVCaptureSessionPreset640x480]) {
            NSLog(@"Set preview port to 640X480");
            self.captureSession.sessionPreset = AVCaptureSessionPreset640x480;
        }

    // We add the preview layer
    self.prevLayer = [AVCaptureVideoPreviewLayer layerWithSession: self.captureSession];

    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    if (orientation == UIInterfaceOrientationLandscapeLeft) {
        self.prevLayer.connection.videoOrientation = AVCaptureVideoOrientationLandscapeLeft;
        self.prevLayer.frame = CGRectMake(0, 0, MAX(self.view.frame.size.width,self.view.frame.size.height), MIN(self.view.frame.size.width,self.view.frame.size.height));
    }
    if (orientation == UIInterfaceOrientationLandscapeRight) {
        self.prevLayer.connection.videoOrientation = AVCaptureVideoOrientationLandscapeRight;
        self.prevLayer.frame = CGRectMake(0, 0, MAX(self.view.frame.size.width,self.view.frame.size.height), MIN(self.view.frame.size.width,self.view.frame.size.height));
    }

    if (orientation == UIInterfaceOrientationPortrait) {
        self.prevLayer.connection.videoOrientation = AVCaptureVideoOrientationPortrait;
        self.prevLayer.frame = CGRectMake(0, 0, MIN(self.view.frame.size.width,self.view.frame.size.height), MAX(self.view.frame.size.width,self.view.frame.size.height));
    }
    if (orientation == UIInterfaceOrientationPortraitUpsideDown) {
        self.prevLayer.connection.videoOrientation = AVCaptureVideoOrientationPortraitUpsideDown;
        self.prevLayer.frame = CGRectMake(0, 0, MIN(self.view.frame.size.width,self.view.frame.size.height), MAX(self.view.frame.size.width,self.view.frame.size.height));
    }

    self.prevLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.view.layer addSublayer: self.prevLayer];
#if USE_MWOVERLAY
    [MWOverlay addToPreviewLayer: self.prevLayer];
#endif

    self.focusTimer = [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(reFocus) userInfo:nil repeats:YES];

    [self CustomOverlay];
}

- (void) CustomOverlay
{
    CGRect bounds = self.view.bounds;
    bounds = CGRectMake(0, 0, bounds.size.width, bounds.size.height);

    UIView* overlayView = [[UIView alloc] initWithFrame:bounds];
    overlayView.autoresizesSubviews = YES;
    overlayView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    overlayView.opaque = NO;

    UIToolbar* toolbar = [[UIToolbar alloc] init];
    toolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    NSMutableArray *items;
    id cancelButton = [[UIBarButtonItem alloc]
                       initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                       target:self
                       action:@selector(closeBtn:)
    ];
    id flexSpace = [[UIBarButtonItem alloc]
                    initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                    target:nil
                    action:nil
    ];
    items = [@[flexSpace, cancelButton, flexSpace] mutableCopy];
    toolbar.items = items;
    bounds = overlayView.bounds;
    [toolbar sizeToFit];
    CGFloat toolbarHeight = [toolbar frame].size.height;
    CGFloat rootViewHeight = CGRectGetHeight(bounds);
    CGFloat rootViewWidth = CGRectGetWidth(bounds);
    CGRect rectArea = CGRectMake(0, rootViewHeight - toolbarHeight, rootViewWidth, toolbarHeight);
    [toolbar setFrame:rectArea];
    [overlayView addSubview: toolbar];
    CGRect redArea = CGRectMake(35, 50, rootViewWidth - 70, rootViewHeight - 100 - toolbarHeight);
    UIView *redView = [[UIView alloc] initWithFrame:redArea];
    redView.backgroundColor = [UIColor clearColor];
    redView.layer.cornerRadius = 5;
    redView.layer.borderWidth = 2;
    redView.layer.borderColor = [UIColor redColor].CGColor;
    [overlayView addSubview: redView];
    [self.view addSubview:overlayView];
}

- (void) onVideoStart: (NSNotification*) note
{
    if (running) {
        return;
    }
    running = YES;

    // lock device and set focus mode
    NSError *error = nil;
    if ([self.device lockForConfiguration: &error]) {
        if ([self.device isFocusModeSupported: AVCaptureFocusModeContinuousAutoFocus])
            self.device.focusMode = AVCaptureFocusModeContinuousAutoFocus;

        if ([self.device isExposureModeSupported: AVCaptureExposureModeContinuousAutoExposure])
            self.device.exposureMode = AVCaptureExposureModeContinuousAutoExposure;
    }
}

- (void) onVideoStop: (NSNotification*) note
{
    if (!running) {
        return;
    }
    [self.device unlockForConfiguration];
    running = NO;
}

#pragma mark -
#pragma mark AVCaptureSession delegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection
{
    if (state != CAMERA) {
        return;
    }

    if (self.state != CAMERA_DECODING) {
        self.state = CAMERA_DECODING;
    }

    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CIImage *ciImage = [self adjust:[CIImage imageWithCVPixelBuffer:imageBuffer] saturation:1.0 shadow:0.3 contrast:1.2 brightness:0.0 sharpnessLuminance:2.0];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];

        // activate license
        NSString *scannerType = [settings objectForKey:@"scannerType"];

        IDScanPDFDetector *pdfDetector = [IDScanPDFDetector detectorWithActivationKey: [settings objectForKey:@"scannerPDFKey"]];
        IDScanMRZDetector *mrzDetector = [IDScanMRZDetector detectorWithActivationKey: [settings objectForKey:@"scannerMRZKey"]];

        NSString *result = @"";
        // detect based on scanner Type
        if ([scannerType isEqualToString:@"pdf"]) {
            result = [pdfDetector detectFromImage:ciImage][@"string"];
        } else if ([scannerType isEqualToString:@"mrz"]) {
            result = [mrzDetector detectFromImage:ciImage][@"string"];
        } else {
            // combined scanner
            result = [pdfDetector detectFromImage:ciImage][@"string"];

            if ([result length] < 4) {
                result = [mrzDetector detectFromImage:ciImage][@"string"];
            }
        }

        // Ignore results less than 4 characters - probably false detection
        if ([result length] > 4) {
            self.state = CAMERA;

            if (self->decodeImage != nil) {
                CGImageRelease(self->decodeImage);
                self->decodeImage = nil;
            }

            dispatch_async(dispatch_get_main_queue(), ^(void) {
                [self.captureSession stopRunning];
                NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
                DecoderResult *notificationResult = [DecoderResult createSuccess:result];
                [center postNotificationName:DecoderResultNotification object: notificationResult];
            });
        }
        else {
            self.state = CAMERA;
        }
    });
}

- (CIImage *)adjust:(CIImage *)ciImage
         saturation:(float)saturation
             shadow:(float)shadow
           contrast:(float)contrast
         brightness:(float)brightness
 sharpnessLuminance:(float)sharpnessLuminance
{
    // saturation
    CIFilter *filter = [CIFilter filterWithName:@"CIColorControls"];
    [filter setValue:ciImage forKey:kCIInputImageKey];
    [filter setValue:[NSNumber numberWithFloat: saturation] forKey:kCIInputSaturationKey];
    ciImage = [filter valueForKey:kCIOutputImageKey];

    // shadow
    CIFilter *shadowFilter = [CIFilter filterWithName:@"CIHighlightShadowAdjust"];
    [shadowFilter setValue:ciImage forKey:kCIInputImageKey];
    [shadowFilter setValue:[NSNumber numberWithFloat: shadow] forKey:@"inputShadowAmount"];
    ciImage = [shadowFilter valueForKey:kCIOutputImageKey];

    // contrast
    CIFilter *contrastFilter = [CIFilter filterWithName:@"CIColorControls"];
    [contrastFilter setValue:ciImage forKey:kCIInputImageKey];
    [contrastFilter setValue:[NSNumber numberWithFloat: contrast] forKey:kCIInputContrastKey];
    ciImage = [contrastFilter valueForKey:kCIOutputImageKey];

    // brightness
    CIFilter *brightnessFilter = [CIFilter filterWithName:@"CIColorControls"];
    [brightnessFilter setValue:ciImage forKey:kCIInputImageKey];
    [brightnessFilter setValue:[NSNumber numberWithFloat: brightness] forKey:kCIInputBrightnessKey];
    ciImage = [brightnessFilter valueForKey:kCIOutputImageKey];

    // sharpnessLuminance
    CIFilter *sharpnessLuminanceFilter = [CIFilter filterWithName:@"CISharpenLuminance"];
    [sharpnessLuminanceFilter setValue:ciImage forKey:kCIInputImageKey];
    [sharpnessLuminanceFilter setValue:[NSNumber numberWithFloat: sharpnessLuminance] forKey:kCIInputSharpnessKey];
    ciImage = [sharpnessLuminanceFilter valueForKey:kCIOutputImageKey];

    return ciImage;
}

#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning
{
    [self stopScanning];

    self.prevLayer = nil;
    [super didReceiveMemoryWarning];
}

- (void)dealloc {
#if !__has_feature(objc_arc)
    [super dealloc];
#endif
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) startScanning {
    self.state = LAUNCHING_CAMERA;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self.captureSession startRunning];
        [self setRecommendedZoomFactor];
    });
    
    self.prevLayer.hidden = NO;
    self.state = CAMERA;
}

- (void)stopScanning {
    [self.captureSession stopRunning];
    self.state = NORMAL;
    self.prevLayer.hidden = YES;
}

- (void) deinitCapture {
    if (self.focusTimer) {
        [self.focusTimer invalidate];
        self.focusTimer = nil;
    }

    if (self.captureSession != nil) {
#if USE_MWOVERLAY
        [MWOverlay removeFromPreviewLayer];
#endif

#if !__has_feature(objc_arc)
        [self.captureSession release];
#endif
        self.captureSession = nil;
        [self.prevLayer removeFromSuperlayer];
        self.prevLayer = nil;
    }
}

- (void) setRecommendedZoomFactor {
    if (@available(iOS 15.0, *)) {
        float deviceMinimumFocusDistance = [self.device minimumFocusDistance];
        
        if (deviceMinimumFocusDistance == -1) {
            return;
        }
        
        CMVideoDimensions formatDimensions = CMVideoFormatDescriptionGetDimensions([self.device.activeFormat formatDescription]);
        float rectOfInterestWidth = (float)formatDimensions.height / (float)formatDimensions.width;
        
        float deviceFieldOfView = [self.device.activeFormat videoFieldOfView];
        float minimumSubjectDistanceForCode = [self minimumSubjectDistanceForCode:deviceFieldOfView minimumCodeSize:20 previewFillPercentage:rectOfInterestWidth];
        
        if (minimumSubjectDistanceForCode < deviceMinimumFocusDistance) {
            float zoomFactor = deviceMinimumFocusDistance / minimumSubjectDistanceForCode;
            
            @try {
                NSError *error;
                if ([self.device lockForConfiguration:&error]) {
                    self.device.videoZoomFactor = zoomFactor;
                    
                    [self.device unlockForConfiguration];
                }
            }
            @catch (id exceptionError) {
                NSLog(@"Could not lock for configuration");
            }
        }
    }
}

- (float) minimumSubjectDistanceForCode:(float)fieldOfView
                        minimumCodeSize:(float)minimumCodeSize
                  previewFillPercentage:(float)previewFillPercentage
{
    /*
        Given the camera horizontal field of view, we can compute the distance (mm) to make a code
        of minimumCodeSize (mm) fill the previewFillPercentage.
     */
    float fieldOfViewDivided = fieldOfView / 2;
    float radians = [self degreesToRadians: fieldOfViewDivided];
    float filledCodeSize = minimumCodeSize / previewFillPercentage;
    
    return filledCodeSize / tan(radians);
}

- (float) degreesToRadians:(float)degrees
{
    return degrees * M_PI / 180;
}

- (void)decodeResultNotification: (NSNotification *)notification {

    if ([notification.object isKindOfClass:[DecoderResult class]]) {
        DecoderResult *obj = (DecoderResult*)notification.object;
        if (obj.succeeded) {
            decodeResult = [[NSString alloc] initWithString:obj.result];

            // Call the delegate to return the decodeResult and dismiss the camera view
            [self.delegate returnScanResult:self scanResult:decodeResult];
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    }
}

- (enum UIInterfaceOrientationMask)supportedInterfaceOrientations {
    UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];

    switch (interfaceOrientation) {
        case UIInterfaceOrientationPortrait:
            return UIInterfaceOrientationMaskPortrait;
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            return UIInterfaceOrientationMaskPortraitUpsideDown;
            break;
        case UIInterfaceOrientationLandscapeLeft:
            return UIInterfaceOrientationMaskLandscapeLeft;
            break;
        case UIInterfaceOrientationLandscapeRight:
            return UIInterfaceOrientationMaskLandscapeRight;
            break;
        default:
            break;
    }

    return UIInterfaceOrientationMaskAll;
}

- (BOOL) shouldAutorotate {
    return YES;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [self toggleTorch];
}

- (IBAction)closeBtn:(id)sender {
    [self.delegate returnScanResult:self scanResult:nil];
    [self dismissViewControllerAnimated:YES completion:nil];
}
@end

// Implementation of the object that returns decoder results (via notification process)
@implementation DecoderResult

@synthesize succeeded;
@synthesize result;

+(DecoderResult *)createSuccess:(NSString *)result {
    DecoderResult *obj = [[DecoderResult alloc] init];
    if (obj != nil) {
        obj.succeeded = YES;
        obj.result = result;
    }
    return obj;
}

+(DecoderResult *)createFailure {
    DecoderResult *obj = [[DecoderResult alloc] init];
    if (obj != nil) {
        obj.succeeded = NO;
        obj.result = nil;
    }
    return obj;
}

- (void)dealloc {
#if !__has_feature(objc_arc)
    [super dealloc];
#endif
    self.result = nil;
}

@end
