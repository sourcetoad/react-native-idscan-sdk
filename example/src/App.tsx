import * as React from 'react';

import { StyleSheet, View, Text } from 'react-native';
import { scan, IDScanner_Constants } from 'react-native-idscan-sdk';

export default function App() {
  const [result, setResult] = React.useState<object | undefined>();

  React.useEffect(() => {
    setTimeout(() => {
      scan(
        IDScanner_Constants.TYPE_PDF,
        {
          // iOS
          iosDetectorPDFLicenseKey: 'iOS IdScanner PDF License Key here',
          iosDetectorMRZLicenseKey: 'iOS IdScanner MRZ License Key here',
          iosParserPDFLicenseKey: 'iOS IdParser PDF License Key here',

          // Android
          androidDetectorPDFLicenseKey:
            'android IdScanner PDF License Key here',
          androidDetectorMRZLicenseKey:
            'android IdScanner MRZ License Key here',
          androidParserPDFLicenseKey: 'android IdParser PDF License Key here',
        },
        (error, data) => {
          console.log(error, data);

          if (!error) {
            setResult(data);
          }
        }
      );
    }, 5000);
  }, []);

  return (
    <View style={styles.container}>
      <Text>Result: {JSON.stringify(result)}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  box: {
    width: 60,
    height: 60,
    marginVertical: 20,
  },
});
