//
//  DBSQLQueryBuilder.m
//  DBCodingServiceExample
//
//  Created by Aleksey Garbarev on 16.04.14.
//
//

#import "DBQueryBuilder.h"
#import "DBEntity.h"
#import "DBEntityField.h"
#import "DBScheme.h"

@interface DBQueryBuilder ()
@property (nonatomic, strong) DBScheme *scheme;
@end

@implementation DBQueryBuilder

- (instancetype)initWithScheme:(DBScheme *)scheme
{
    self = [super init];
    if (self) {
        self.scheme = scheme;
    }
    return self;
}

- (DBQuery)queryToSelectEntity:(DBEntity *)entity withPrimaryKey:(id)primaryKeyValue
{
    DBQuery query;
    query.query = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ = ?", entity.table, entity.primary.column];
    query.args = @[primaryKeyValue];
    return query;
}

- (DBQuery)queryToInsertObject:(id)object withFields:(NSSet *)fields tryReplace:(BOOL)replace
{
    DBEntity *entity = [self.scheme entityForClass:[object class]];
    NSMutableString *query = [NSMutableString stringWithFormat:@"INSERT%@ INTO %@(",replace?@" OR REPLACE":@"",[entity table]];
    NSMutableArray *args = [NSMutableArray array];
    
    [self enumerateColumnsInObject:object withEntity:entity fields:fields withBlock:^(id value, NSString *column, NSUInteger index) {
        NSString *comma = (index == 0) ? @"" : @", ";
        [query appendFormat:@"%@%@", comma, column];
        [args addObject:value];
    }];
    
    [query appendString:@") VALUES ("];
    
    for (int i = 0; i < [args count]; i++){
        NSString *comma = (i == 0) ? @"" : @", ";
        [query appendFormat:@"%@?",comma];
    }
    
    [query appendString:@")"];
    
    DBQuery queryStruct;
    queryStruct.query = query;
    queryStruct.args = args;
    return queryStruct;
}

- (DBQuery)queryToUpdateObject:(id)object withFields:(NSSet *)fields
{
    DBEntity *entity = [self.scheme entityForClass:[object class]];

    NSAssert(![self isEmptyPrimaryKey:[object valueForKeyPath:entity.primary.property]], @"Object must have non-empty primary key for UPDATE");
    
    NSMutableString *query = [NSMutableString stringWithFormat:@"UPDATE %@ SET ", [entity table]];
    NSMutableArray *args = [NSMutableArray array];
    
    NSMutableSet *fieldsWithoutPrimaryKey = [fields mutableCopy];
    [fieldsWithoutPrimaryKey removeObject:entity.primary];
    
    [self enumerateColumnsInObject:object withEntity:entity fields:fieldsWithoutPrimaryKey withBlock:^(id value, NSString *column, NSUInteger index) {
        NSString *comma = (index == 0) ? @"" : @", ";
        [query appendFormat:@"%@%@ = ?", comma, column];
        [args addObject:value];
    }];

    [query appendFormat:@" WHERE %@ = ?", entity.primary.column];
    [args addObject:[object valueForKey:entity.primary.property]];
    
    DBQuery queryStruct;
    queryStruct.query = query;
    queryStruct.args = args;
    return queryStruct;
}

- (DBQuery)queryToDeleteObject:(id)object
{
    DBEntity *entity = [self.scheme entityForClass:[object class]];
    DBQuery query;
    query.query = [NSString stringWithFormat:@"DELETE FROM %@ WHERE %@ = ?", entity.table, entity.primary.column];
    query.args = @[[object valueForKey:entity.primary.property]];
    return query;
}

- (DBQuery)queryToDeleteRelation:(DBManyToManyRelation *)relation fromObject:(id)fromObject toObject:(id)toObject
{
    DBQuery query;
    query.query = [NSString stringWithFormat:@"DELETE FROM %@ WHERE %@ = ? AND %@ = ?", relation.relationTable, relation.fromEntityIdColumn, relation.toEntityIdColumn];
    query.args = @[[fromObject valueForKey:relation.fromEntity.primary.property], [toObject valueForKey:relation.toEntity.primary.property]];
    return query;
}

- (DBQuery)queryToNullifyRelation:(DBEntityRelation *)relation fromObject:(id)fromObject toObject:(id)toObject
{
    DBQuery query;
    query.query = [NSString stringWithFormat:@"UPDATE %@ SET %@ = ? WHERE %@ = ?",[relation.toEntity table], relation.toEntityField.column, relation.toEntity.primary.column];
    query.args = @[[NSNull null], [toObject valueForKey:relation.toEntity.primary.property]];
    return query;
}

#pragma mark - Utils

- (DBEntity *)entityForRelatedField:(DBEntityField *)field inEntity:(DBEntity *)entity
{
    __block DBEntity *foreignEntity = nil;
    [self.scheme enumerateToOneRelationsFromEntity:entity usingBlock:^(DBEntityField *fromField, DBEntity *toEntity, DBEntityField *toField, BOOL *stop) {
        if ([field isEqualToField:fromField]) {
            foreignEntity = toEntity;
            *stop = YES;
        }
    }];
    return foreignEntity;
}

- (void)enumerateColumnsInObject:(id)object withEntity:(DBEntity *)entity fields:(NSSet *)fields withBlock:(void(^)(id value, NSString *column, NSUInteger index))block
{
    NSUInteger index = 0;
    
    for (DBEntityField *field in fields) {
        if (field.column && field.property) {
            
            id value = [object valueForKey:field.property];
            
            DBEntity *foreignEntity = [self entityForRelatedField:field inEntity:entity];
            if (foreignEntity) {
                value = [value valueForKey:foreignEntity.primary.property];
            }
            
            if ([entity.primary isEqualToField:field] && [self isEmptyPrimaryKey:value]) {
                value = nil;
            }
            
            if (!value) {
                value = [NSNull null];
            }
            
            block(value, field.column, index);
            index++;
        }
    }
}

- (BOOL)isEmptyPrimaryKey:(id)primaryKey
{
    return primaryKey == nil
    || ([primaryKey isKindOfClass:[NSNumber class]] && [primaryKey integerValue] == 0)
    || ([primaryKey isKindOfClass:[NSString class]] && [primaryKey length] == 0);
}


@end
