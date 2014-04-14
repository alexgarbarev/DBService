//
//  DBConnectionScheme.m
//  DBCodingServiceExample
//
//  Created by Aleksey Garbarev on 14.04.14.
//
//

#import "DBTableConnectionScheme.h"
#import "DBTableConnection.h"

@implementation DBTableConnectionScheme {
    DBTableConnection *connection;
}

@synthesize parentScheme;

- (instancetype)initWithTableConnection:(DBTableConnection *)connectionScheme
{
    self = [super init];
    if (self) {
        connection = connectionScheme;
    }
    return self;
}

- (void)encodeObject:(id)object withCoder:(DBCoder *)encoder
{
    
}

- (id)decodeObject:(id)object fromCoder:(DBCoder *)decoder
{
    return decoder;
}

- (NSString *)primaryKeyColumn
{
    return connection.relationPKColumn;
}

- (id)primaryKeyValueFromObject:(id)object
{
    return nil;
}

- (void)setPrimaryKeyValue:(id)primaryKey forObject:(id)object
{
    
}

- (NSString *)table
{
    return connection.table;
}


- (NSString *)foreignKeyColumnForRelationWithScheme:(id<DBScheme>)scheme
{
    return nil;
}

- (id<DBScheme>)schemeForForeignKeyColumn:(NSString *)column
{
    return nil;
}


#pragma mark - Deletion callbacks

- (DBSchemeDeleteRule)deleteRuleForOneToOneRelatedObjectWithScheme:(id<DBScheme>)scheme forColumn:(NSString *)column
{
    return [self.parentScheme deleteRuleForManyToManyRelatedObjectWithScheme:scheme andConnection:connection];
}

- (DBSchemeDeleteRule)deleteRuleForOneToManyRelatedObjectWithScheme:(id<DBScheme>)scheme connectedOnForeignColumn:(NSString *)foreignColumn
{
    return DBSchemeDeleteRuleNoAction;
}

- (DBSchemeDeleteRule)deleteRuleForManyToManyRelationWithConnection:(DBTableConnection *)connection
{
    return DBSchemeDeleteRuleNoAction;
}

- (DBSchemeDeleteRule)deleteRuleForManyToManyRelatedObjectWithScheme:(id<DBScheme>)scheme andConnection:(DBTableConnection *)connection
{
    return DBSchemeDeleteRuleNoAction;
}


@end
