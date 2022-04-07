import { NativeModules, Platform } from 'react-native';

const LINKING_ERROR =
  `The package 'react-native-idscan-sdk' doesn't seem to be linked. Make sure: \n\n` +
  Platform.select({ ios: "- You have run 'pod install'\n", default: '' }) +
  '- You rebuilt the app after installing the package\n' +
  '- You are not using Expo managed workflow\n';

const IdscanSdk = NativeModules.IdscanSdk
  ? NativeModules.IdscanSdk
  : new Proxy(
      {},
      {
        get() {
          throw new Error(LINKING_ERROR);
        },
      }
    );

type ScanResult = (error: object, scanData: object) => void;

export function scan(
  cameraKey: string,
  parserKey: string,
  onScanComplete: ScanResult
) {
  IdscanSdk.scan(cameraKey, parserKey, (error: object, data: object) => {
    onScanComplete(error, data);
  });
}
