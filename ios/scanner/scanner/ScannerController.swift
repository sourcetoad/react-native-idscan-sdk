//
//  ScannerController.swift
//  scanner
//
//  Created by Kendall Kelly on 8/30/22.
//

import Foundation
import IDScanPDFDetector
import IDScanMRZDetector
import IDScanPDFParser
import IDScanMRZParser



class Scanner {
    
    let pdfDetector: IDScanPDFDetector // = IDScanPDFDetector() for demo mode or you can specify activationKey later
    let mrzDetector: IDScanMRZDetector // = IDScanMRZDetector() for demo mode or you can specify activationKey later
    let pdfParser:   IDScanPDFParser   // = IDScanPDFParser() for demo mode or you can specify activationKey later
    let mrzParser:   IDScanMRZParser   // IDScanMRZParser is free to use and doesn't need a license key
    
    init(pdfDetectorKey: String, mrzDetectorKey: String, pdfParserKey: String) {
        self.pdfDetector = IDScanPDFDetector(activationKey: pdfDetectorKey)
        self.mrzDetector = IDScanMRZDetector(activationKey: mrzDetectorKey)
        self.pdfParser   = IDScanPDFParser(activationKey: pdfParserKey)
        self.mrzParser   = IDScanMRZParser()
    }
    
    public func cameraPermissions() {
        
    }
    public func resultFromDetector(_ rawString: String, type: String) { // you can use the IDScanIDDetector (https://github.com/IDScanNet/IDScanIDDetectorIOS) to get the raw string from device camera or images
        switch type {
            case "pdf":
                if let parsedData = pdfParser.parse(rawString) as? [String : String]
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
    
    private func resultFromParser(_ parsedData: [String : String], type: String) {
        let firstName = parsedData["firstName"]
        let birthDate = parsedData["birthDate"]
        let licenseNumber = parsedData["licenseNumber"]
        print("SCAN SUCCESSFUL")
        print(firstName)
        print(birthDate)
        print(licenseNumber)
        //etc
    }
    
}
