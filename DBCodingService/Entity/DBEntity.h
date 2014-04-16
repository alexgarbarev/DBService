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

@interface DBEntity : NSObject

@property (nonatomic, strong) Class objectClass;
@property (nonatomic, strong) NSString *table;

@property (nonatomic, strong) NSOrderedSet *fields;

@property (nonatomic, strong) DBEntityField *primary;

@property (nonatomic, strong) DBEntity *parent;
@property (nonatomic, getter = isAbstract) BOOL abstract;

- (BOOL)isEqualToEntity:(DBEntity *)entity;

- (DBEntityField *)fieldWithColumn:(NSString *)column;

@end
