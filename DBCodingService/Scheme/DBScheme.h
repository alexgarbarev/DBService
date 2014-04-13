//
//  DBScheme.h
//  DBCodingServiceExample
//
//  Created by Aleksey Garbarev on 12.04.14.
//
//

#import "NSObject+DBScheme.h"

typedef enum {
    DBSchemeDeleteRuleNoAction,
    DBSchemeDeleteRuleNullify,
    DBSchemeDeleteRuleCascade,
    DBSchemeDeleteRuleDeny
} DBSchemeDeleteRule;

@class DBCoder;
@class DBTableConnection;

@protocol DBScheme <NSObject>

- (void)encodeObject:(id)object withCoder:(DBCoder *)encoder;
- (id)decodeObject:(id)object fromCoder:(DBCoder *)decoder;

- (NSString *)primaryKeyColumn;
- (id)primaryKeyValueFromObject:(id)object;
- (void)setPrimaryKeyValue:(id)primaryKey forObject:(id)object;

- (NSString *)table;

#pragma mark - Foreign keys

- (NSString *)foreignKeyColumnForRelationWithScheme:(id<DBScheme>)scheme;
- (id<DBScheme>)schemeForForeignKeyColumn:(NSString *)column;

#pragma mark - Parent scheme support

@property (nonatomic, strong) id<DBScheme> parentScheme;

#pragma mark - Deletion callbacks

- (DBSchemeDeleteRule)deleteRuleForOneToOneRelatedObjectWithScheme:(id<DBScheme>)scheme forColumn:(NSString *)column;

- (DBSchemeDeleteRule)deleteRuleForOneToManyRelatedObjectWithScheme:(id<DBScheme>)scheme connectedOnForeignColumn:(NSString *)foreignColumn;

- (DBSchemeDeleteRule)deleteRuleForManyToManyRelationWithConnection:(DBTableConnection *)connection;

- (DBSchemeDeleteRule)deleteRuleForManyToManyRelatedObjectWithScheme:(id<DBScheme>)scheme andConnection:(DBTableConnection *)connection;

@end

