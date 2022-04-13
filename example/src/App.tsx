import React from 'react';

import { StyleSheet, View, Text, TouchableOpacity } from 'react-native';
import { scan, IDSCANNER_CONSTANTS } from 'react-native-idscan-sdk';

export default function App() {
  const [result, setResult] = React.useState<object | undefined>();

  // methods
  const triggerScanner = () => {
    scan(
      IDSCANNER_CONSTANTS.TYPE_PDF,
      {
        // iOS
        iosDetectorPDFLicenseKey: 'iOS IdScanner PDF License Key here',
        iosDetectorMRZLicenseKey: 'iOS IdScanner MRZ License Key here',
        iosParserPDFLicenseKey: 'iOS IdParser PDF License Key here',

        // Android
        androidDetectorPDFLicenseKey: 'android IdScanner PDF License Key here',
        androidDetectorMRZLicenseKey: 'android IdScanner MRZ License Key here',
        androidParserPDFLicenseKey: 'android IdParser PDF License Key here',
      },
      (error, data) => {
        console.log(error, data);

        if (!error) {
          setResult(data);
        }
      }
    );
  };

  return (
    <View style={styles.container}>
      <TouchableOpacity
        onPress={triggerScanner}
        style={{
          width: 200,
          height: 40,
          backgroundColor: '#a2f6a5',
          alignItems: 'center',
          justifyContent: 'center',
          marginBottom: 10,
          borderRadius: 5,
        }}
      >
        <Text>Scan ID</Text>
      </TouchableOpacity>
      <Text>Result: {JSON.stringify(result)}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: '#fff',
  },
  box: {
    width: 60,
    height: 60,
    marginVertical: 20,
  },
});
