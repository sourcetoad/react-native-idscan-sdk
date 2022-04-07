require "json"

package = JSON.parse(File.read(File.join(__dir__, "package.json")))

Pod::Spec.new do |s|
  s.name         = "react-native-idscan-sdk"
  s.version      = package["version"]
  s.summary      = package["description"]
  s.homepage     = package["homepage"]
  s.license      = package["license"]
  s.authors      = package["author"]

  s.platforms    = { :ios => "10.0" }
  s.source       = { :git => "https://github.com/sourcetoad/react-native-idscan-sdk.git", :tag => "#{s.version}" }

  s.vendored_frameworks = 'ios/sdk/IDScanPDFDetector.xcframework', 'ios/sdk/IDScanMRZDetector.xcframework', 'ios/sdk/IDScanPDFParser.xcframework', 'ios/sdk/IDScanMRZParser.xcframework'
  s.source_files = "ios/**/*.{h,m,mm}"

  s.dependency "React-Core"
end
