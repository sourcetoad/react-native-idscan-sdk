//
//  idscanParser.h
//  idscanParser
//
//  Created by Ossir on 14.07.2020.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface DriverLicense : NSObject
{
    NSDate* __birthDate, *__issueDate, *__expirationDate;
}

//new properties
@property (nonatomic,retain) NSString* countryCode;
@property (readonly,nonatomic,retain) NSString* documentType;

//technical info
@property (retain, nonatomic) NSDictionary *raw_parsed_fields;
@property (retain, nonatomic) NSString *specification;
@property (retain, nonatomic) NSString *parserName;
@property (readonly, nonatomic, retain) NSDictionary *fields;//parsedfields filtered (available fields)

//Document Info
@property (readonly, retain, nonatomic) NSString* licenseNumber;
@property (readonly, retain, nonatomic) NSString* expirationDate;//date
@property ( retain, nonatomic) NSString *IIN;//aliases
@property (readonly, retain, nonatomic) NSString */*IIN,*/issuerIdNum;//aliases

@property (readonly, retain, nonatomic) NSString* issuedBy;
@property (readonly, retain, nonatomic) NSString* endorsementsCode;
@property (readonly, retain, nonatomic) NSString* classificationCode;
@property (readonly, retain, nonatomic) NSString *restrictionsCode,*restrictionCode;//aliases
@property (readonly, retain, nonatomic) NSString* issueDate;//date

//Customer Info
@property (readonly, retain, nonatomic) NSString* fullName;
@property (readonly, retain, nonatomic) NSString* lastName;
@property (readonly, retain, nonatomic) NSString* firstName;
@property (readonly, retain, nonatomic) NSString* middleName;
@property (readonly, retain, nonatomic) NSString* birthdate;//date
@property (readonly, retain, nonatomic) NSString* nameSuffix;
@property (readonly, retain, nonatomic) NSString* namePrefix;

//Customer address
@property (readonly, retain, nonatomic) NSString* address1;
@property (readonly, retain, nonatomic) NSString* address2;
@property (readonly, retain, nonatomic) NSString* city;
@property (retain, nonatomic) NSString* jurisdictionCode;
@property (readonly, retain, nonatomic) NSString* postalCode;
@property ( retain, nonatomic) NSString* country;

//Customer physical description
@property (readonly, retain, nonatomic) NSString* gender;
@property (readonly, retain, nonatomic) NSString* eyeColor;
@property (readonly, retain, nonatomic) NSString* height;
@property (readonly, retain, nonatomic) NSString *weightLBS,*weightKG,*weight/*weight=weightLBS*/;
@property (readonly, retain, nonatomic) NSString* hairColor;
@property (readonly, retain, nonatomic) NSString* race;

+(NSString*)dlpUniqueId;

- (BOOL)parseDLString:(NSString *)inputString hideSerialAlert:(BOOL)hideSerialAlert;
- (NSString*)getVersion;
- (void)showLogs:(BOOL)showLogs;
- (NSArray *)availableFields;
- (NSString *)valueForField:(NSString *)field;
- (id)valueForDateField:(NSString *)field withFormat:(NSString *)dateFormat;
//addon init
- (id)initWithInput:(NSString*)tracksString parseSucced:(BOOL**)success  hideSerialAlert:(BOOL)hideSerialAlert;

@end

@interface NSString (DriverLicense)
- (NSDictionary *)parseDLStringForDict;
@end

