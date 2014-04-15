//
//  DBEntityColumn.h
//  DBCodingServiceExample
//
//  Created by Aleksey Garbarev on 15.04.14.
//
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, DBEntityFieldType) {
    DBEntityFieldTypeInteger16,
    DBEntityFieldTypeInteger32,
    DBEntityFieldTypeInteger64,
    DBEntityFieldTypeFloat,
    DBEntityFieldTypeDouble,
    DBEntityFieldTypeString,
    DBEntityFieldTypeDate,
    DBEntityFieldTypeData,
    DBEntityFieldTypeBoolean
};

@interface DBEntityField : NSObject

@property (nonatomic, strong) NSString *column;
@property (nonatomic, strong) NSString *property;

@property (nonatomic) DBEntityFieldType type;
@property (nonatomic, strong) id defaultValue;

@property (nonatomic) BOOL indexed;

- (BOOL)isEqualToField:(DBEntityField *)field;

@end
