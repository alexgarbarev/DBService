//
//  DBEntity.h
//  DBCodingServiceExample
//
//  Created by Aleksey Garbarev on 15.04.14.
//
//

typedef int DBEntityColumnType;

@class DBEntityField;
@class DBEntityRelation;
@class DBParentRelation;

@interface DBEntity : NSObject

@property (nonatomic, strong) Class objectClass;
@property (nonatomic, strong) NSString *table;

@property (nonatomic, strong) NSOrderedSet *fields;

@property (nonatomic, strong) DBEntityField *primary;

@property (nonatomic, strong) DBParentRelation *parentRelation;
@property (nonatomic, getter = isAbstract) BOOL abstract;

- (BOOL)isEqualToEntity:(DBEntity *)entity;

- (DBEntityField *)fieldWithColumn:(NSString *)column;


+ (BOOL)isEmptyPrimaryKey:(id)primaryKey;


@end
