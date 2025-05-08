//
//  IDScanIDParser.swift
//  IDScanIDParser
//
//  Created by Andrey Simakov on 11.12.2024.
//
import Foundation

@objc public class IDScanIDParser: NSObject {
    
    @discardableResult
    @objc
    public func setLicense(_ license: String) -> Bool {
        if let cLicenseKey = strdup(license) {
            defer {
                free(cLicenseKey)
            }
            return _setLicense(cLicenseKey)
        }
        return false
    }
    
    @objc
    public func parse(_ trackString: String) -> [String: String]? {
        if let trackStringBase64 = trackString.data(using: .utf8)?.base64EncodedString(), let cTrackString = strdup(trackStringBase64) {
            defer {
                free(cTrackString)
            }
            
            if let result = _parse(cTrackString), let resultString = String(validatingUTF8: result),
               !resultString.isEmpty, resultString != "null" {
                _freeResult(result)
                return jsonToDictionary(resultString)
            }
            return nil
        }
        return nil
    }
    
    private func jsonToDictionary(_ jsonString: String) -> [String: String]? {
        if let jsonData = jsonString.data(using: .utf8) {
            do {
                if let jsonDict = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] {
                    let converted = jsonDict.mapValues { $0 is NSNull ? "" : "\($0)" }
                    return converted
                }
            } catch {
                print("Error converting JSON string to Dictionary: \(error.localizedDescription)")
                return nil
            }
        }
        return nil
    }
    
    @objc
    public override init() {
        super.init()
    }
}

@_silgen_name("setLicense")
fileprivate func _setLicense(_ licenseKey: UnsafePointer<CChar>) -> Bool

@_silgen_name("parseDL")
fileprivate func _parse(_ trackString: UnsafePointer<CChar>) -> UnsafePointer<CChar>?

@_silgen_name("freeResult")
fileprivate func _freeResult(_ result: UnsafePointer<CChar>) 