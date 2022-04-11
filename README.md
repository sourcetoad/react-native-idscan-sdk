# react-native-idscan-sdk

React Native ID Scanner wrapper for idscan sdk

## Installation

```sh
npm install react-native-idscan-sdk
```

## Usage

```js
import { TouchableOpacity, Text } from 'react-native'
import { scan, IDScanner_Constants } from 'react-native-idscan-sdk';

// ...

const onScanID = () => {
  scan(
    IDScanner_Constants.TYPE_PDF, // TYPE_COMBINED, TYPE_MRZ, TYPE_PDF
    {
      // iOS
      iosDetectorPDFLicenseKey: 'iOS IdScanner PDF License Key here',
      iosDetectorMRZLicenseKey: 'iOS IdScanner MRZ License Key here',
      iosParserPDFLicenseKey: 'iOS IdParser PDF License Key here',

      // Android
      androidDetectorPDFLicenseKey: 'android IdScanner PDF License Key here',
      androidDetectorMRZLicenseKey: 'android IdScanner MRZ License Key here',
      androidParserPDFLicenseKey: 'android IdParser PDF License Key here',
    }
    (error, scannedData) => console.log(error, scannedData)
  );
}

// ...

<TouchableOpacity
  onPress={onScanID}
>
  <Text>Scan My ID</Text>
</TouchableOpacity>

```

## iOS Quirks

This plugins requires the following usage descriptions:

- `NSCameraUsageDescription` specifies the reason for your app to access the device's camera.
- `NSPhotoLibraryUsageDescription` specifies the reason for your app to access the user's photo library.

## Android Quirks

- Add idscan-public maven repository to the project build.gradle file.

```
allprojects {
    repositories {
        ...
        maven {
            url 'https://www.myget.org/F/idscan-public/maven/'
        }
        ...
    }
}
```

- You must ask for camera permission. Insert this to your project's `AndroidManifest.xml`

```
<uses-permission android:name="android.permission.CAMERA" />
```

## Contributing

See the [contributing guide](CONTRIBUTING.md) to learn how to contribute to the repository and the development workflow.

## License

MIT
