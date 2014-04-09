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

#import "NSInvocation_Class.h"

@implementation DBCoder{

    //Values:
    NSString * rootObjectClass;
    id pkColumnValue;

    DBCoderData *data;
    
    //Scheme:
    NSString * table;
    NSString * pkColumnName;
    NSString * pkColumnKey;
    
    //Service, used to decoding:
    DBCodingService *decodingService;
    
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
    [data setObject:object withClass:[object class] forColumn:column];
}

- (void)encodeObject:(id) object withSchemeClass:(Class)objectClass forColumn:(NSString *)column
{
    [data setObject:object withClass:objectClass forColumn:column];
}

- (void)encodeObjects:(NSArray *)objects withForeignKeyColumn:(NSString *)foreignKeyColumn
{
    [data setObjects:objects withForeignKey:foreignKeyColumn];
}

#pragma mark - Decoding

- (id)decodeObjectForColumn:(NSString *)column
{
    return [data valueForColumn:column];
}

- (void)decodeObjectsFromConnection:(DBTableConnection *)connection decoding:(DBDecodingBlock) codingBlock
{
    NSString * query = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ = ?", connection.table, connection.encoderColumn];
    
    pkColumnValue = [self decodeObjectForColumn:connection.encodedObjectColumn];
    
    NSArray * decoders = [decodingService decodersFromSQLQuery:query withArgs:@[pkColumnValue]];
    
    [decoders enumerateObjectsUsingBlock:^(DBCoder * decoder, NSUInteger idx, BOOL *stop) {
        if (codingBlock) codingBlock(decoder);
    }];
}

- (id<DBCoding>)decodeObjectOfClass:(Class)objectClass withSchemeClass:(Class)asClass forColumn:(NSString *)column
{
    id objectId = [self decodeObjectForColumn:column];
    return [decodingService objectWithId:objectId andClass:objectClass withSchemeClass:asClass];
}

- (id<DBCoding>)decodeObjectOfClass:(Class)objectClass forColumn:(NSString *)column
{
    return [self decodeObjectOfClass:objectClass withSchemeClass:objectClass forColumn:column];
}

- (NSArray *)decodeObjectsOfClass:(Class)schemeClass withForeignKeyColumn:(NSString *)foreignKeyColumn
{
    if (!foreignKeyColumn) {
        NSLog(@"You are trying to fetch objects of %@ class with nil foreign key.",schemeClass);
        return nil;
    }
    
    if (!pkColumnValue) {
        NSLog(@"You are trying to fetch objects of %@ class when foreign key (%@) refers to nil",schemeClass, foreignKeyColumn);
        return nil;
    }
    
    NSString *foreignTable = [schemeClass dbTable];
    
    NSString *query = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ = ?", foreignTable, foreignKeyColumn];
    
    NSArray *decoders = [decodingService decodersFromSQLQuery:query withArgs:@[pkColumnValue]];
    
    NSMutableArray *objects = [[NSMutableArray alloc] initWithCapacity:[decoders count]];
    
    for (DBCoder *decoder in decoders) {
        id object = [decodingService objectOfClass:schemeClass fromDecoder:decoder];
        [objects addObject:object];
    }
    
    return objects;
}

@end


@implementation DBCoder(DBService)

#pragma mark - Initialization

- (id) initWithConnection:(DBTableConnection *) connection{
    self = [super init];
    if (self) {
        pkColumnName = [connection encoderColumn];
        table = [connection table];
        shouldSkipZeroValues = YES;
        data = [[DBCoderData alloc] initWithEncodingIgnoredColumns:@[pkColumnName]];
    }
    return self;
}

- (id) initWithResultSet:(FMResultSet *) resultSet dbService:(DBCodingService *) service{
    self = [super init];
    if (self) {
        decodingService = service;
        shouldSkipZeroValues = YES;
        data = [DBCoderData new];

        for (int i = 0; i < [resultSet columnCount]; i++){
            NSString * column = [resultSet columnNameForIndex:i];
            id object = [resultSet objectForColumnIndex:i];
            
            if (![object isKindOfClass:[NSNull class]]) {
                [data setObject:object withClass:[object class] forColumn:column];
            }
        }
    }
    return self;
}

- (id) initWithDBObject:(id<DBCoding>) rootObject as:(Class) objectClass{
    self = [super init];
    if (self) {
        
        shouldSkipZeroValues = YES;
        pkColumnName = [objectClass dbPKColumn];
        table = [objectClass dbTable];
        
        /* Ignoring primary key encoding, since we access to primaryKey property directly (ignoring to avoid duplicating) */
        data = [[DBCoderData alloc] initWithEncodingIgnoredColumns:@[pkColumnName]];

        [NSInvocation invokeTarget:rootObject withSelector:@selector(encodeWithDBCoder:) ofClass:objectClass arg:self];
        
        rootObjectClass = NSStringFromClass(objectClass);
        pkColumnKey = [NSInvocation resultOfInvokingTarget:rootObject withSelector:@selector(dbPKProperty) ofClass:objectClass];
        pkColumnValue = [(NSObject *)rootObject valueForKey:pkColumnKey];
    }
    return self;
}

- (id) initWithDBObject:(id<DBCoding>) rootObject{
    return [self initWithDBObject:rootObject as:[rootObject class]];
}

#pragma mark - Primary key managment

+ (BOOL) isCorrectPrimaryKey:(id) pkKey{
    BOOL havePK = NO;
    
    // exist only if not nil
    havePK = pkKey != nil;
    
    // and not 0 if nsnumber
    if (pkKey && [pkKey isKindOfClass:[NSNumber class]]){
        havePK = [pkKey integerValue] != dbPrimaryKeyUndefined;
    }
    
    return havePK;
    
}

- (BOOL) havePrimaryKey{
    return [DBCoder isCorrectPrimaryKey:pkColumnValue];
}

- (id) primaryKey{
    return pkColumnValue;
}

- (void) setPrimaryKey:(id) pkValue{
    pkColumnValue = pkValue;
}

- (void) setPrimaryKeyColumn:(NSString *)pkColumn
{
    pkColumnName = pkColumn;
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

- (void) updateStatement:(DBStatement) statement{
    
    NSMutableString * query = [[NSMutableString alloc] initWithFormat:@"UPDATE %@ SET", table];
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
    
    [query appendFormat:@" WHERE %@ = ?;",pkColumnName];
    [arguments addObject:pkColumnValue];
    
    if (statement) statement(query, arguments);
}

#pragma mark - Delete statment

- (void) deleteStatement:(void(^)(NSString * query, NSArray * args)) statement{
    
    NSString * query = [[NSString alloc] initWithFormat:@"DELETE FROM %@ WHERE %@ = ?",table, pkColumnName];
    NSArray * arguments = @[pkColumnValue];
    
    if (!pkColumnValue){
        query = nil;
        arguments = nil;
    }
    
    if (statement) statement(query, arguments);
}

#pragma mark - Insert query

- (void) insertStatement:(DBStatement) statement replace:(BOOL) replace{
    
    NSMutableArray * arguments = [[NSMutableArray alloc] initWithCapacity:[data columnsCount]];
    NSMutableString * query = [[NSMutableString alloc] initWithFormat:@"INSERT%@ INTO %@(",replace?@" OR REPLACE":@"",table];
    
    __block int columsToInsert = 0;
    void(^addColumn)(NSString * column, id value) = ^(NSString * column, id value){
        BOOL isFirst = columsToInsert == 0;
        [query appendFormat:@"%@%@", isFirst ? @"":@", ",column];
        [arguments addObject:value];
        columsToInsert++;
    };
    
    BOOL insertPK = [self havePrimaryKey];
    int keys_count = [data columnsCount];
    
    if (insertPK){
        addColumn(pkColumnName, pkColumnValue);
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
        Class objectClass = [data valueClassForColumn:column];
        
        /* If it is db-coding object */
        if ([objectClass conformsToProtocol:@protocol(DBCoding)])
        {
            id object = [data valueForColumn:column];
            /* save object in db by calling block */
            id insertedId = block(object, objectClass);
            if (insertedId){
                /* replace db object value with his id */
                [data setObject:insertedId withClass:nil forColumn:column];
            } else {
                [data removeObjectForColumn:column];
            }
        }
    }
}

- (void)enumerateOneToManyRelatedObjects:(DBInsertingForeignBlock)block
{
    if (block) {
        [data enumerateOnToManyObjects:block];
    }
}

- (void) enumerateManyToManyRelationCoders:(void(^)(DBCoder * connection_coder, DBTableConnection *connection))block
{
    if (block) {
        [data enumerateManyToManyCoders:block];
    }
}

- (Class) rootObjectClass{
    return NSClassFromString(rootObjectClass);
}

@end
