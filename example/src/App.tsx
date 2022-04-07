import * as React from 'react';

import { StyleSheet, View, Text } from 'react-native';
import { scan } from 'react-native-idscan-sdk';

export default function App() {
  const [result, setResult] = React.useState<object | undefined>();

  React.useEffect(() => {
    setTimeout(() => {
      scan('KEY-1', 'KEY-2', (error, data) => {
        console.log(error, data);

        if (!error) {
          setResult(data);
        }
      });
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
