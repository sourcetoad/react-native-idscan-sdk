/**
 * Drivers License Data Format
 */
export type DLData = {
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
};

/**
 * Scanner Scan Result
 */
export type ScanResult = (error: object, scanData: DLData) => void;

/**
 * Scanner Types
 */
export enum IdScannerTypes {
  TYPE_ALL,
  TYPE_MRZ,
  TYPE_PDF,
}
