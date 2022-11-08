import { NativeModules, Platform } from 'react-native';
import type { DLData, ScanResult, IdScannerTypes, APIKeys } from './types';

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

// SDK Constants
const SDKConstants = IdscanSdk.getConstants();

export const IDSCANNER_CONSTANTS = {
  /**
   * Combined PDF and MRZ Scanner
   */
  TYPE_COMBINED: SDKConstants.TYPE_COMBINED,

  /**
   * Scan Passports
   */
  TYPE_MRZ: SDKConstants.TYPE_MRZ,

  /**
   * Scan Drivers Licenses
   */
  TYPE_PDF: SDKConstants.TYPE_PDF,
};

/**
 * Scan a Drivers License or Passport
 * @param type Supported scanner/parser types
 * @param apiKeys Object containing android and iOS API keys
 * @param onScanComplete Handle scan complete function
 */
export function scan(
  type: IdScannerTypes,
  apiKeys: APIKeys,
  onScanComplete: ScanResult
) {
  IdscanSdk.scan(type, apiKeys, (error: object, data: DLData) => {
    if (Platform.OS === 'android') {
      data.birthDate = data.birthDate || data.birthdate
      data.IIN = data.IIN || data.iin
    } 
    onScanComplete(error, data);
  });
}
