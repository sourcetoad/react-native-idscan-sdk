/**
 * Drivers License Data Format
 */
export type DLData = {
  [key: string]: string;
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
  endorsementsCodeDescription: string;
  issuedBy: string;
  firstName: string;
  middleName: string;
  lastName: string;
  nameSuffix: string;
  restrictionsCode: string;
  restrictionsCodeDescription: string;
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
  hazmateExpDate: string;
  cardRevisiondate: string;
  complianceType: string;
};

/**
 * Scanner Scan Result
 */
export type ScanResult = (error: object, scanData: DLData) => void;

/**
 * Scanner Types
 */
export enum IdScannerTypes {
  TYPE_COMBINED,
  TYPE_MRZ,
  TYPE_PDF,
}

/**
 * API Keys Types
 */
export type APIKeys = {
  // iOS
  iosDetectorPDFLicenseKey: string;
  iosDetectorMRZLicenseKey: string;
  iosParserPDFLicenseKey: string;

  // Android
  androidDetectorPDFLicenseKey: string;
  androidDetectorMRZLicenseKey: string;
  androidParserPDFLicenseKey: string;
};
