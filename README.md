# react-native-idscan-sdk

React Native ID Scanner wrapper for IDScan.net [ID Parsing](https://idscan.net/scanning-solutions/enterprise/id-parsing-sdk/) and [Camera](https://docs.idscan.net/camerascan/index.html).

## Installation

```sh
npm install react-native-idscan-sdk
```

## iOS Setup

This plugins requires the following usage descriptions added to the application plist:

- `NSCameraUsageDescription` specifies the reason for your app to access the device’s camera.
- `NSPhotoLibraryUsageDescription` specifies the reason for your app to access the user’s photo library.

## Android Setup

- Add idscan-public maven repository to the project build.gradle file.

```groovy
allprojects {
    repositories {
        // ...
        maven {
            url 'https://www.myget.org/F/idscan-public/maven/'
        }
        // ...
    }
}
```

- Insert the following into the project `AndroidManifest.xml` to request camera permission.

```
<uses-permission android:name="android.permission.CAMERA" />
```

## Usage

```js
import { TouchableOpacity, Text } from 'react-native'
import { scan, IDSCANNER_CONSTANTS } from 'react-native-idscan-sdk';

// ...

const onScanID = () => {
  scan(
    IDSCANNER_CONSTANTS.TYPE_PDF, // TYPE_COMBINED, TYPE_MRZ, TYPE_PDF
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

### PDF417 Response

```js
{
  namePrefix: string;
  IIN: string;
  race: string;
  gender: string;
  fullName: string;
  issuerIdNum: string;
  city: string;
  weight: string;
  height: string;
  address1: string;
  address2: string;
  classificationCode: string;
  issueDate: string;
  licenseNumber: string;
  expirationDate: string;
  endorsementsCode: string;
  issuedBy: string;
  firstName: string;
  middleName: string;
  lastName: string;
  nameSuffix: string;
  restrictionsCode: string;
  birthDate: string;
  countryCode: string;
  jurisdictionCode: string;
  hairColor: string;
  eyeColor: string;
  documentType: string;
  country: string;
  weightKG: string;
  weightLBS: string;
  restrictionCode: string;
  postalCode: string;
  specification: string;
}
```

### MRZ Response

```js
{
  Dob: string;
  DocumentNumber: string;
  DocumentType: string;
  Exp: string;
  FirstName: string;
  FullName: string;
  Gender: string;
  IssuingState: string;
  LastName: string;
  Line1: string;
  Line2: string;
  Line3: string;
  Nationality: string;
}
```

## Contributing

See the [contributing guide](CONTRIBUTING.md) to learn how to contribute to the repository and the development workflow.

## License

[MIT](LICENSE.md)
