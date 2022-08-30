import UIKit
import AVFoundation
import IDScanPDFDetector
import IDScanMRZDetector
import IDScanPDFParser
import IDScanMRZParser



class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {

    
    let captureSession = AVCaptureSession()
    let scanner = Scanner(
        pdfDetectorKey: "Activation key here",
        mrzDetectorKey: "Activation key here",
        pdfParserKey: "Activation key here"
    )
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        captureSession.beginConfiguration()
        let videoDevice = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back)
        
        guard
            let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice!),
            captureSession.canAddInput(videoDeviceInput)
            else { return }
        
        captureSession.addInput(videoDeviceInput)
        
        let photoOutput = AVCaptureVideoDataOutput()
        guard captureSession.canAddOutput(photoOutput) else { return }
        captureSession.sessionPreset = .photo
        captureSession.addOutput(photoOutput)
        let queue = DispatchQueue(label: "videoqueue")

        photoOutput.setSampleBufferDelegate(self, queue: queue)
        captureSession.commitConfiguration()
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        previewLayer.frame = view.layer.bounds
        view.layer.addSublayer(previewLayer)
        captureSession.startRunning()
        print("scanning")
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        //Method 1
        if let resultPDF = scanner.pdfDetector.detect(from: sampleBuffer), let resultString = resultPDF["string"] as? String {
            scanner.resultFromDetector(resultString, type: "pdf")
            return
        }
        
        if let resultMRZ = scanner.mrzDetector.detect(from: sampleBuffer), let resultString = resultMRZ["string"] as? String {
            scanner.resultFromDetector(resultString, type: "mrz")
            return
        }
        
        //Method 2
        let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        var ciImage = CIImage(cvPixelBuffer: imageBuffer!)
            //process an image in the necessary way (brightness, contrast, etc)
            
        if let resultPDF = scanner.pdfDetector.detect(from: ciImage), let resultString = resultPDF["string"] as? String {
            scanner.resultFromDetector(resultString, type: "pdf")
                return
            }
            
        if let resultMRZ = scanner.mrzDetector.detect(from: ciImage), let resultString = resultMRZ["string"] as? String {
            scanner.resultFromDetector(resultString, type: "mrz")
                return
            }
        }
        
    }

