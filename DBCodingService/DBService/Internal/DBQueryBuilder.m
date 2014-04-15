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

@implementation DBQueryBuilder

- (DBQuery)queryToSelectEntity:(DBEntity *)entity withPrimaryKey:(id)primaryKeyValue
{
    DBQuery query;
    query.query = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ = ?", entity.table, entity.primary.column];
    query.args = @[primaryKeyValue];
    return query;
}

- (DBQuery)queryToInsertObject:(id)object withEntity:(DBEntity *)entity tryReplace:(BOOL)replace
{
    NSMutableString *query = [NSMutableString stringWithFormat:@"INSERT%@ INTO %@(",replace?@" OR REPLACE":@"",[entity table]];
    NSMutableArray *args = [NSMutableArray array];
    
    [self enumerateColumnsInObject:object withEntity:entity excluding:nil withBlock:^(id value, NSString *column, NSUInteger index) {
        NSString *comma = (column == 0) ? @"" : @", ";
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

- (DBQuery)queryToUpdateObject:(id)object withEntity:(DBEntity *)entity
{
    NSMutableString *query = [NSMutableString stringWithFormat:@"UPDATE %@ SET", [entity table]];
    NSMutableArray *args = [NSMutableArray array];

    [self enumerateColumnsInObject:object withEntity:entity excluding:[NSSet setWithObject:entity.primary.column] withBlock:^(id value, NSString *column, NSUInteger index) {
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

- (DBQuery)queryToDeleteObject:(id)object withEntity:(DBEntity *)entity
{
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

- (void)enumerateColumnsInObject:(id)object withEntity:(DBEntity *)entity excluding:(NSSet *)columnsToExclude withBlock:(void(^)(id value, NSString *column, NSUInteger index))block
{
    NSUInteger index = 0;
    
    for (DBEntityField *field in [entity fields]) {
        if (field.column && field.property && ![columnsToExclude containsObject:field.column]) {
            
            id value = [object valueForKey:field.property];
            
            DBEntity *foreignEntity = [entity relationForField:field].toEntity;
            if (foreignEntity) {
                value = [value valueForKey:foreignEntity.primary.property];
            }
            
            if (value) {
                block(value, field.column, index);
                index++;
            }
        }
    }
}

@end
