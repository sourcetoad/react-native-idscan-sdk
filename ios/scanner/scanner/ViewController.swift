import UIKit
import AVFoundation
import IDScanPDFDetector
import IDScanMRZDetector
import IDScanPDFParser
import IDScanMRZParser



class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {

    
    let captureSession = AVCaptureSession()
    let pdfDetector = IDScanPDFDetector(activationKey: "your License key") // = IDScanPDFDetector() for demo mode or you can specify activationKey later
    let mrzDetector = IDScanMRZDetector(activationKey: "your License key") // = IDScanMRZDetector() for demo mode or you can specify activationKey later
    let pdfParser = IDScanPDFParser(activationKey: "your License key") // = IDScanPDFParser() for demo mode or you can specify activationKey later
    let mrzParser = IDScanMRZParser() // IDScanMRZParser is free to use and doesn't need a license key
    
    
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
            if let resultPDF = pdfDetector?.detect(from: sampleBuffer), let resultString = resultPDF["string"] as? String {
                resultFromDetector(resultString, type: "pdf")
                return
            }
            
            if let resultMRZ = mrzDetector?.detect(from: sampleBuffer), let resultString = resultMRZ["string"] as? String {
                resultFromDetector(resultString, type: "mrz")
                return
            }
            
            //Method 2
              let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
              var ciImage = CIImage(cvPixelBuffer: imageBuffer!)
              //process an image in the necessary way (brightness, contrast, etc)
              
              if let resultPDF = pdfDetector?.detect(from: ciImage), let resultString = resultPDF["string"] as? String {
                  resultFromDetector(resultString, type: "pdf")
                  return
              }
              
              if let resultMRZ = mrzDetector?.detect(from: ciImage), let resultString = resultMRZ["string"] as? String {
                  resultFromDetector(resultString, type: "mrz")
                  return
              }
        }

        func resultFromDetector(_ rawString: String, type: String) { //you can use the IDScanIDDetector (https://github.com/IDScanNet/IDScanIDDetectorIOS) to get the raw string from device camera or images
            switch type {
                case "pdf":
                    if let parsedData = pdfParser?.parse(rawString) as? [String : String]
                    {
                        resultFromParser(parsedData, type: type)
                    }
                case "mrz":
                    if let parsedData = mrzParser.parse(rawString) as? [String : String]
                    {
                        resultFromParser(parsedData, type: type)
                    }
                default: break
            }
        }

        func resultFromParser(_ parsedData: [String : String], type: String) {
            let firstName = parsedData["firstName"]
            let birthDate = parsedData["birthDate"]
            let licenseNumber = parsedData["licenseNumber"]
            print(firstName)
            print(birthDate)
            print(licenseNumber)
            //etc
        }
    
        
        
        
    }

