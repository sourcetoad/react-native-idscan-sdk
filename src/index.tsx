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
enum IdScannerTypes {
  TYPE_ALL,
  TYPE_MRZ,
  TYPE_PDF,
}

// SDK Constants
const SDKConstants = IdscanSdk.getConstants();
export const IDScanner_Constants = {
  TYPE_ALL: SDKConstants.TYPE_ALL,
  TYPE_MRZ: SDKConstants.TYPE_MRZ,
  TYPE_PDF: SDKConstants.TYPE_PDF,
};

export function scan(
  type: IdScannerTypes,
  cameraKey: string,
  parserKey: string,
  onScanComplete: ScanResult
) {
  IdscanSdk.scan(type, cameraKey, parserKey, (error: object, data: object) => {
    onScanComplete(error, data);
  });
}
