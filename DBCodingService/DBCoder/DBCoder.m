//
//  DBCoder.m
//  qliq
//
//  Created by Aleksey Garbarev on 06.12.12.
//
//

#import "DBCoder.h"
#import "DBCoder_DBService.h"
#import "DBCoderData.h"
#import "DBCodingService.h"
#import "DBScheme.h"
#import "DBTableConnectionScheme.h"

#import "NSInvocation_Class.h"

@implementation DBCoder
{
    //Values:
    DBCoderData *data;
    
    //Scheme:
    id<DBScheme> scheme;
    
    //Decoding:
    DBCodingService *decodingService;
    
    id encodingObject;
    
    BOOL shouldSkipZeroValues;
}

@dynamic shouldSkipZeroValues;

- (void) setShouldSkipZeroValues:(BOOL) _skipEmptyString{
    shouldSkipZeroValues = _skipEmptyString;
}

- (BOOL)shouldSkipZeroValues{
    return shouldSkipZeroValues;
}

- (NSString *)description{
    return [NSString stringWithFormat:@"%@ \ndata=%@",[super description],data];
}

#pragma mark - Encoding

- (void)encodeObjects:(NSArray *)objects connection:(DBTableConnection *)connection coding:(DBCodingBlock)codingBlock
{
    NSAssert(![encodingObject isKindOfClass:[DBTableConnection class]], @"Many-To-Many relations not supported for connection-table encoders");

    NSMutableArray * coders = [[NSMutableArray alloc] initWithCapacity:[objects count]];
    
    for (id object in objects){
        DBCoder * coder = [[DBCoder alloc] initWithConnection:connection];
        if (codingBlock) {
            codingBlock(coder, object);
        }
        [coders addObject:coder];
    }
    
    [data setCoders:coders forConnection:connection];
}

- (void)encodeObject:(id)object forColumn:(NSString *)column
{
    [data setObject:object withScheme:[[object class] scheme] forColumn:column];
}

- (void)encodeObject:(id)object withScheme:(id<DBScheme>)_scheme forColumn:(NSString *)column
{
    [data setObject:object withScheme:_scheme forColumn:column];
}

- (void)encodeObjects:(NSArray *)objects withForeignKeyColumn:(NSString *)foreignKeyColumn
{
    NSAssert(![encodingObject isKindOfClass:[DBTableConnection class]], @"One-To-Many relations not supported for connection-table encoders");
    id<DBScheme>_scheme = [[[objects firstObject] class] scheme];
    NSParameterAssert(_scheme);
    [data setObjects:objects withScheme:_scheme withForeignKey:foreignKeyColumn];
}

#pragma mark - Decoding

- (id)decodeObjectForColumn:(NSString *)column
{
    return [data valueForColumn:column];
}

- (void)decodeObjectsFromConnection:(DBTableConnection *)connection decoding:(DBDecodingBlock)codingBlock
{
    NSString * query = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ = ?", connection.table, connection.encoderColumn];
    
    id primaryKey = [scheme primaryKeyValueFromObject:encodingObject];
    
    NSArray * decoders = [decodingService decodersWithScheme:nil fromSQLQuery:query withArgs:@[primaryKey]];
    
    [decoders enumerateObjectsUsingBlock:^(DBCoder *decoder, NSUInteger idx, BOOL *stop) {
        if (codingBlock) codingBlock(decoder);
    }];
}

- (id)decodeObjectWithScheme:(id<DBScheme>)_scheme forColumn:(NSString *)column
{
    if (_scheme) {
        id objectId = [self decodeObjectForColumn:[_scheme primaryKeyColumn]];
        return [decodingService objectWithId:objectId andScheme:_scheme];
    } else {
        return [self decodeObjectForColumn:column];
    }
}

- (NSArray *)decodeObjectsWithScheme:(id<DBScheme>)_scheme withForeignKeyColumn:(NSString *)foreignKeyColumn
{
    if (!foreignKeyColumn) {
        NSLog(@"You are trying to fetch objects of %@ scheme with nil foreign key.",_scheme);
        return nil;
    }
    
    id primaryKey = [scheme primaryKeyValueFromObject:encodingObject];
    if (!primaryKey) {
        NSLog(@"You are trying to fetch objects of %@ scheme when foreign key (%@) refers to nil",_scheme, foreignKeyColumn);
        return nil;
    }

    NSString *foreignTable = [scheme table];
    
    NSString *query = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ = ?", foreignTable, foreignKeyColumn];
    
    NSArray *decoders = [decodingService decodersWithScheme:_scheme fromSQLQuery:query withArgs:@[primaryKey]];
    
    NSMutableArray *objects = [[NSMutableArray alloc] initWithCapacity:[decoders count]];
    
    for (DBCoder *decoder in decoders) {
        id object = [decodingService objectWithScheme:_scheme fromDecoder:decoder];
        [objects addObject:object];
    }
    
    return objects;
}

@end


@implementation DBCoder(DBService)

- (id<DBScheme>)scheme
{
    return scheme;
}

#pragma mark - Initialization

- (id)initWithConnection:(DBTableConnection *)connection
{
    self = [super init];
    if (self) {
        data = [[DBCoderData alloc] init];
        scheme = [[DBTableConnectionScheme alloc] initWithTableConnection:connection];
        shouldSkipZeroValues = YES;
        encodingObject = connection;
    }
    return self;
}

- (id)initWithResultSet:(FMResultSet *)resultSet scheme:(id<DBScheme>)_scheme dbService:(DBCodingService *)service
{
    self = [super init];
    if (self) {
        decodingService = service;
        shouldSkipZeroValues = YES;
        data = [DBCoderData new];
        scheme = _scheme;

        for (int i = 0; i < [resultSet columnCount]; i++){
            NSString * column = [resultSet columnNameForIndex:i];
            id object = [resultSet objectForColumnIndex:i];
            
            if (![object isKindOfClass:[NSNull class]]) {
                [data setObject:object withScheme:nil forColumn:column];
            }
        }
    }
    return self;
}

/* Init for encoding object */
- (id)initWithObject:(id)object scheme:(id<DBScheme>)_scheme
{
    self = [super init];
    if (self) {
        scheme = _scheme;
        encodingObject = object;
        
        shouldSkipZeroValues = YES;
        
        /* Ignoring primary key encoding, since we access to primaryKey property directly (ignoring to avoid duplicating) */
        data = [[DBCoderData alloc] initWithEncodingIgnoredColumns:@[[scheme primaryKeyColumn]]];

        [scheme encodeObject:object withCoder:self];
    }
    return self;
}

#pragma mark - Primary key managment

- (id)primaryKeyToEncode
{
    return [scheme primaryKeyValueFromObject:encodingObject];
}

- (BOOL) shouldSkipObject:(id)object{
    
    BOOL skipObject = NO;
    
    if (shouldSkipZeroValues){
        if ([object isKindOfClass:[NSString class]] && [object length] == 0)
            skipObject = YES;
        
        if ([object isKindOfClass:[NSNumber class]] && [object intValue] == 0)
            skipObject = YES;
    }
    
    return skipObject;
}

#pragma mark - Update query

- (void)updateStatement:(DBStatement)statement
{
    NSMutableString * query = [[NSMutableString alloc] initWithFormat:@"UPDATE %@ SET", [scheme table]];
    NSMutableArray * arguments = [[NSMutableArray alloc] initWithCapacity:[data columnsCount]];
    
    __block int columsToUpdate = 0;
    void(^addColumn)(NSString * column, id value) = ^(NSString * column, id value){
        BOOL isFirst = columsToUpdate == 0;
        [query appendFormat:@"%@ %@ = ?",isFirst?@"":@",",column];
        [arguments addObject:value];
        columsToUpdate++;
    };
    
    int keys_count = [data columnsCount];
    for (NSString * key in [data allColumns]){
       
        id object = [data valueForColumn:key];;
        if (![self shouldSkipObject:object]){
            addColumn(key, object);
        }
        
        keys_count--;
    }
    
    if (arguments.count == 0) {
        arguments = nil;
        query = nil;
    }
    
    [query appendFormat:@" WHERE %@ = ?;",[scheme primaryKeyColumn]];
    [arguments addObject:[scheme primaryKeyValueFromObject:encodingObject]];
    
    if (statement) statement(query, arguments);
}

#pragma mark - Delete statment

- (void)deleteStatement:(void(^)(NSString * query, NSArray * args)) statement
{
    id primaryKey = [scheme primaryKeyValueFromObject:encodingObject];
    
    NSString *query;
    NSArray *arguments;
    
    if (!primaryKey) {
        query = nil;
        arguments = nil;
    } else {
        query = [[NSString alloc] initWithFormat:@"DELETE FROM %@ WHERE %@ = ?",[scheme table], [scheme primaryKeyColumn]];
        arguments = @[primaryKey];
    }
    
    if (statement) statement(query, arguments);
}

#pragma mark - Insert query

- (void)insertStatement:(DBStatement) statement replace:(BOOL)replace
{
    
    NSMutableArray * arguments = [[NSMutableArray alloc] initWithCapacity:[data columnsCount]];
    NSMutableString * query = [[NSMutableString alloc] initWithFormat:@"INSERT%@ INTO %@(",replace?@" OR REPLACE":@"",[scheme table]];
    
    __block int columsToInsert = 0;
    void(^addColumn)(NSString * column, id value) = ^(NSString * column, id value){
        BOOL isFirst = columsToInsert == 0;
        [query appendFormat:@"%@%@", isFirst ? @"":@", ",column];
        [arguments addObject:value];
        columsToInsert++;
    };
    
    BOOL insertPK = [self primaryKeyToEncode] != nil;
    int keys_count = [data columnsCount];
    
    if (insertPK){
        addColumn([scheme primaryKeyColumn], [self primaryKeyToEncode]);
    }
    
    for (NSString * key in [data allColumns]){

        id object = [data valueForColumn:key];

        if (![self shouldSkipObject:object]){
            addColumn(key, object);
        }
        
        keys_count--;
    }
    
    [query appendString:@") VALUES ("];
    for (int i = 0; i < columsToInsert; i++){
        [query appendFormat:@"?%@",i+1==columsToInsert?@"":@", "];
    }
    [query appendString:@")"];
    
    if (arguments.count == insertPK){
        query = nil;
        arguments = nil;
    }
    
    if (statement) statement(query, arguments);
    
}

#pragma mark - Enumerations

- (void)enumerateOneToOneRelatedObjects:(DBInsertingBlock)block
{    
    for (NSString * column in [data allColumns])
    {
        id<DBScheme> objectScheme = [data valueSchemeForColumn:column];
        
        /* If it is db-coding object */
        if (objectScheme)
        {
            id object = [data valueForColumn:column];
            /* save object in db by calling block */
            id insertedId = block(object, objectScheme, column);
            if (insertedId){
                /* replace db object value with his id */
                [data setObject:insertedId withScheme:nil forColumn:column];
            } else {
                [data removeObjectForColumn:column];
            }
        }
    }
}

- (NSArray *)allManyToManyConnections
{
    return [data allManyToManyConnections];
}

- (void)enumerateManyToManyCodersForConnection:(DBTableConnection *)connection usingBlock:(void(^)(DBCoder *connectionCoder))block
{
    if (block) {
        [data enumerateManyToManyCodersForConnection:connection usingBlock:block];
    }
}

- (void) enumerateManyToManyRelationCoders:(void(^)(DBCoder * connectionCoder, DBTableConnection *connection))block
{
    if (block) {
        for (DBTableConnection *connection in [data allManyToManyConnections]) {
            [data enumerateManyToManyCodersForConnection:connection usingBlock:^(DBCoder *connectionCoder) {
                block(connectionCoder, connection);
            }];
        }
    }
}

- (NSArray *)allOneToManyForeignKeys
{
    return [data allOneToManyForeignKeys];
}

- (void)enumerateOneToManyRelatedObjectsForKey:(NSString *)foreignKey withBlock:(void(^)(id object, id<DBScheme>scheme))block
{
    if (block) {
        [data enumerateOneToManyObjectsForKey:foreignKey usingBlock:block];
    }
}

- (void)enumerateOneToManyRelatedObjects:(DBInsertingForeignBlock)block
{
    if (block) {
        for (NSString *foreignKey in [data allOneToManyForeignKeys]) {
            [data enumerateOneToManyObjectsForKey:foreignKey usingBlock:^(id value, id<DBScheme>_scheme) {
                block(value, _scheme, foreignKey);
            }];
        }
    }
}

@end
