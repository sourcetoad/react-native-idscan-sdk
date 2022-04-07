#include <mach/mach_host.h>
#import "ScannerViewController.h"

// IDScan Libraries
@import IDScanPDFDetector;

@implementation ScannerViewController {
    AVCaptureSession *_captureSession;
    AVCaptureDevice *_device;
    AVCaptureVideoPreviewLayer *_prevLayer;
    bool running;
    NSString * lastFormat;
    
    MainScreenState state;
    
    CGImageRef    decodeImage;
    NSString *    decodeResult;
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
    NSLog(@"IDScanner: On iOS simulator camera is not Supported");
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
    //NSLog(@"refocus");
    
    NSError *error;
    if ([self.device lockForConfiguration:&error]) {
        
        if ([self.device isFocusPointOfInterestSupported]){
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
            
            if([self.device isFocusModeSupported: AVCaptureFocusModeContinuousAutoFocus])
                self.device.focusMode = AVCaptureFocusModeContinuousAutoFocus;
            
            [self.device unlockForConfiguration];
        } else {
            
        }
    }
}

- (void)initCapture
{
    /*We setup the input*/
    self.device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    AVCaptureDeviceInput *captureInput = [AVCaptureDeviceInput deviceInputWithDevice:self.device error:nil];
    /*We setup the output*/
    AVCaptureVideoDataOutput *captureOutput = [[AVCaptureVideoDataOutput alloc] init];
    captureOutput.alwaysDiscardsLateVideoFrames = YES;
    //captureOutput.minFrameDuration = CMTimeMake(1, 10); Uncomment it to specify a minimum duration for each video frame
    [captureOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
    // Set the video output to store frame in BGRA (It is supposed to be faster)
    
    NSString* key = (NSString*)kCVPixelBufferPixelFormatTypeKey;
    // Set the video output to store frame in 422YpCbCr8(It is supposed to be faster)
    
    //************************Note this line
    NSNumber* value = [NSNumber numberWithUnsignedInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange];
    
    NSDictionary* videoSettings = [NSDictionary dictionaryWithObject:value forKey:key];
    [captureOutput setVideoSettings:videoSettings];
    
    //And we create a capture session
    self.captureSession = [[AVCaptureSession alloc] init];
    //We add input and output
    [self.captureSession addInput:captureInput];
    [self.captureSession addOutput:captureOutput];
    
    if ([self.captureSession canSetSessionPreset:AVCaptureSessionPreset1280x720])
    {
        NSLog(@"Set preview port to 1280X720");
        self.captureSession.sessionPreset = AVCaptureSessionPreset1280x720;
    } else
        //set to 640x480 if 1280x720 not supported on device
        if ([self.captureSession canSetSessionPreset:AVCaptureSessionPreset640x480])
        {
            NSLog(@"Set preview port to 640X480");
            self.captureSession.sessionPreset = AVCaptureSessionPreset640x480;
        }
    
    
    // Limit camera FPS to 15 for single core devices (iPhone 4 and older) so more CPU power is available for decoder
    host_basic_info_data_t hostInfo;
    mach_msg_type_number_t infoCount;
    infoCount = HOST_BASIC_INFO_COUNT;
    host_info( mach_host_self(), HOST_BASIC_INFO, (host_info_t)&hostInfo, &infoCount ) ;
    
    if (hostInfo.max_cpus < 2){
        if ([self.device respondsToSelector:@selector(setActiveVideoMinFrameDuration:)]){
            [self.device lockForConfiguration:nil];
            [self.device setActiveVideoMinFrameDuration:CMTimeMake(1, 15)];
            [self.device unlockForConfiguration];
        } else {
            AVCaptureConnection *conn = [captureOutput connectionWithMediaType:AVMediaTypeVideo];
            [conn setVideoMinFrameDuration:CMTimeMake(1, 15)];
        }
    }
    
    /*We add the preview layer*/
    self.prevLayer = [AVCaptureVideoPreviewLayer layerWithSession: self.captureSession];
    
    if (self.interfaceOrientation == UIInterfaceOrientationLandscapeLeft){
        self.prevLayer.connection.videoOrientation = AVCaptureVideoOrientationLandscapeLeft;
        self.prevLayer.frame = CGRectMake(0, 0, MAX(self.view.frame.size.width,self.view.frame.size.height), MIN(self.view.frame.size.width,self.view.frame.size.height));
    }
    if (self.interfaceOrientation == UIInterfaceOrientationLandscapeRight){
        self.prevLayer.connection.videoOrientation = AVCaptureVideoOrientationLandscapeRight;
        self.prevLayer.frame = CGRectMake(0, 0, MAX(self.view.frame.size.width,self.view.frame.size.height), MIN(self.view.frame.size.width,self.view.frame.size.height));
    }
    
    
    if (self.interfaceOrientation == UIInterfaceOrientationPortrait) {
        self.prevLayer.connection.videoOrientation = AVCaptureVideoOrientationPortrait;
        self.prevLayer.frame = CGRectMake(0, 0, MIN(self.view.frame.size.width,self.view.frame.size.height), MAX(self.view.frame.size.width,self.view.frame.size.height));
    }
    if (self.interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown) {
        self.prevLayer.connection.videoOrientation = AVCaptureVideoOrientationPortraitUpsideDown;
        self.prevLayer.frame = CGRectMake(0, 0, MIN(self.view.frame.size.width,self.view.frame.size.height), MAX(self.view.frame.size.width,self.view.frame.size.height));
    }
    
    
    self.prevLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.view.layer addSublayer: self.prevLayer];
#if USE_MWOVERLAY
    [MWOverlay addToPreviewLayer:self.prevLayer];
#endif
    
    self.focusTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(reFocus) userInfo:nil repeats:YES];
    
    [self CustomeOverlay];
}

- (void) CustomeOverlay
{
    CGRect bounds = self.view.bounds;
    bounds = CGRectMake(0, 0, bounds.size.width, bounds.size.height);
    
    UIView* overlayView = [[UIView alloc] initWithFrame:bounds];
    overlayView.autoresizesSubviews = YES;
    overlayView.autoresizingMask    = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    overlayView.opaque              = NO;
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
    CGFloat toolbarHeight  = [toolbar frame].size.height;
    CGFloat rootViewHeight = CGRectGetHeight(bounds);
    CGFloat rootViewWidth  = CGRectGetWidth(bounds);
    CGRect  rectArea       = CGRectMake(0, rootViewHeight - toolbarHeight, rootViewWidth, toolbarHeight);
    [toolbar setFrame:rectArea];
    [overlayView addSubview: toolbar];
    CGRect  redArea       = CGRectMake(35, 50, rootViewWidth - 70, rootViewHeight - 100 - toolbarHeight);
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
    if(running)
        return;
    running = YES;
    
    // lock device and set focus mode
    NSError *error = nil;
    if([self.device lockForConfiguration: &error])
    {
        if([self.device isFocusModeSupported: AVCaptureFocusModeContinuousAutoFocus])
            self.device.focusMode = AVCaptureFocusModeContinuousAutoFocus;
    }
}

- (void) onVideoStop: (NSNotification*) note
{
    if(!running)
        return;
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
    
    if (self.state != CAMERA_DECODING)
    {
        self.state = CAMERA_DECODING;
    }
    
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    //Lock the image buffer
    CVPixelBufferLockBaseAddress(imageBuffer,0);
    //Get information about the image
    baseAddress = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(imageBuffer,0);
    int pixelFormat = CVPixelBufferGetPixelFormatType(imageBuffer);
    switch (pixelFormat) {
        case kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange:
            //NSLog(@"Capture pixel format=NV12");
            bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(imageBuffer,0);
            width = bytesPerRow;//CVPixelBufferGetWidthOfPlane(imageBuffer,0);
            height = CVPixelBufferGetHeightOfPlane(imageBuffer,0);
            break;
        case kCVPixelFormatType_422YpCbCr8:
            //NSLog(@"Capture pixel format=UYUY422");
            bytesPerRow = (int) CVPixelBufferGetBytesPerRowOfPlane(imageBuffer,0);
            width = CVPixelBufferGetWidth(imageBuffer);
            height = CVPixelBufferGetHeight(imageBuffer);
            int len = width * height;
            int dstpos = 1;
            for (int i=0; i < len; i++){
                baseAddress[i] = baseAddress[dstpos];
                dstpos += 2;
            }
            
            break;
        default:
            //    NSLog(@"Capture pixel format=RGB32");
            break;
    }
    
    unsigned char *frameBuffer = malloc(width * height);
    memcpy(frameBuffer, baseAddress, width * height);
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];

        IDScanPDFDetector *pdfDetector = [IDScanPDFDetector detectorWithActivationKey: [settings objectForKey:@"cameraKey"]];
        
        if (frameBuffer != nil) {
            NSString *result = [pdfDetector detectFromSampleBuffer:frameBuffer][@"string"];
            
            free(frameBuffer);
            NSLog(@"Frame decoded");
            
            //CVPixelBufferUnlockBaseAddress(imageBuffer,0);
            
            //ignore results less than 4 characters - probably false detection
            if ( [result length] > 4 )
            {
                NSLog(@"Detected PDF417: %@", result);
                self.state = CAMERA;
                
                if (decodeImage != nil)
                {
                    CGImageRelease(decodeImage);
                    decodeImage = nil;
                }
                
                dispatch_async(dispatch_get_main_queue(), ^(void) {
                    [self.captureSession stopRunning];
                    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
                    DecoderResult *notificationResult = [DecoderResult createSuccess:result];
                    [center postNotificationName:DecoderResultNotification object: notificationResult];
                });
            }
            else
            {
                self.state = CAMERA;
            }
        }
        else
        {
            self.state = CAMERA;
        }
    });
    
}

#pragma mark -
#pragma mark Memory management

- (void)viewDidUnload
{
    [self stopScanning];
    
    self.prevLayer = nil;
    [super viewDidUnload];
}

- (void)dealloc {
#if !__has_feature(objc_arc)
    [super dealloc];
#endif
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) startScanning {
    self.state = LAUNCHING_CAMERA;
    [self.captureSession startRunning];
    self.prevLayer.hidden = NO;
    self.state = CAMERA;
}

- (void)stopScanning {
    [self.captureSession stopRunning];
    self.state = NORMAL;
    self.prevLayer.hidden = YES;
}

- (void) deinitCapture {
    if (self.focusTimer){
        [self.focusTimer invalidate];
        self.focusTimer = nil;
    }
    
    if (self.captureSession != nil){
#if USE_MWOVERLAY
        [MWOverlay removeFromPreviewLayer];
#endif
        
#if !__has_feature(objc_arc)
        [self.captureSession release];
#endif
        self.captureSession=nil;
        
        [self.prevLayer removeFromSuperlayer];
        self.prevLayer = nil;
    }
}


- (void)decodeResultNotification: (NSNotification *)notification {
    
    if ([notification.object isKindOfClass:[DecoderResult class]])
    {
        DecoderResult *obj = (DecoderResult*)notification.object;
        if (obj.succeeded)
        {
            decodeResult = [[NSString alloc] initWithString:obj.result];
            
            // call the delegate to return the decodeResult and dismiss the camera view
            [self.delegate returnScanResult:self scanResult:decodeResult];
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    }
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        //To continue scanning
        [self startScanning];
    }
}

- (NSUInteger)supportedInterfaceOrientations {
    
    
    UIInterfaceOrientation interfaceOrientation =[[UIApplication sharedApplication] statusBarOrientation];
    
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

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [self toggleTorch];
    
}

- (IBAction)closeBtn:(id)sender {
    [self.delegate returnScanResult:self scanResult:nil];
    [self dismissViewControllerAnimated:YES completion:nil];
}
@end

/*
 *  Implementation of the object that returns decoder results (via the notification
 *    process)
 */

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

