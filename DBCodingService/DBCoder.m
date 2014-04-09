//
//  DBCoder.m
//  qliq
//
//  Created by Aleksey Garbarev on 06.12.12.
//
//

#import "DBCoder.h"
#import "DBCoder_DBService.h"
#import "DBCodingService.h"

#import "NSInvocation_Class.h"

@implementation DBCoder{

    //Values:
    NSArray * colums;
    NSMutableDictionary * valuesForColums;
    NSMutableDictionary * classesForColumns;
    NSString * rootObjectClass;
    id pkColumnValue;
    
    
    //Scheme:
    NSString * table;
    NSString * pkColumnName;
    NSString * pkColumnKey;
    
    //Relations:
    NSArray * relatedCoders;
    
    //Service, used to decoding:
    DBCodingService * dbService;
    
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
    return [NSString stringWithFormat:@"%@ \nvalues:%@\ncolums:%@",[super description],valuesForColums,colums];
}

#pragma mark - coding/decoding

- (void) encodeObjects:(NSArray *) objects connection:(DBTableConnection *) connection coding:(DBCodingBlock) codingBlock{
    
    NSMutableArray * coders = [[NSMutableArray alloc] init];
    
    for (id object in objects){
        DBCoder * coder = [[DBCoder alloc] initWithConnection:connection];
        [coder encodingRootObjectBlock:^{
            if (codingBlock) codingBlock(coder, object);
        }];
        [coders addObject:coder];
    }
    
    relatedCoders = coders;
}

- (void) encodeObject:(id) object forColumn:(NSString *) column{
    if (object && column){
        valuesForColums[column] = object;
    }
}

- (void) encodeObject:(id) object withSchemeClass:(Class)objectClass forColumn:(NSString *)column{
    [self encodeObject:object forColumn:column];
    classesForColumns[column] = NSStringFromClass(objectClass);
}

- (id) decodeObjectForColumn:(NSString *) column{
    return valuesForColums[column];
}

- (void) decodeObjectsFromConnection:(DBTableConnection *) connection decoding:(DBDecodingBlock) codingBlock{
    
    NSString * query = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ = ?", connection.table, connection.onColumn];
    
    pkColumnValue = [self decodeObjectForColumn:connection.byColumn];
    
    NSArray * decoders = [dbService decodersFromSQLQuery:query withArgs:@[pkColumnValue]];
    
    [decoders enumerateObjectsUsingBlock:^(DBCoder * decoder, NSUInteger idx, BOOL *stop) {
        if (codingBlock) codingBlock(decoder);
    }];
}

- (id<DBCoding>) decodeDBObjectOfClass:(Class) objectClass withSchemeClass:(Class) asClass forColumn:(NSString *) column{
    id objectId = [self decodeObjectForColumn:column];
    return [dbService objectWithId:objectId andClass:objectClass withSchemeClass:asClass];
}

- (id<DBCoding>) decodeDBObjectOfClass:(Class)objectClass forColumn:(NSString *)column{
    return [self decodeDBObjectOfClass:objectClass withSchemeClass:objectClass forColumn:column];
}

@end


@implementation DBCoder(DBService)

#pragma mark - Initialization

- (id) initWithConnection:(DBTableConnection *) connection{
    self = [super init];
    if (self) {
        pkColumnName = [connection onColumn];
        table = [connection table];
        shouldSkipZeroValues = YES;
    }
    return self;
}

- (id) initWithResultSet:(FMResultSet *) resultSet dbService:(DBCodingService *) service{
    self = [super init];
    if (self) {
        dbService = service;
        shouldSkipZeroValues = YES;
        valuesForColums = [NSMutableDictionary new];

        for (int i = 0; i < [resultSet columnCount]; i++){
            NSString * column = [resultSet columnNameForIndex:i];
            id object = [resultSet objectForColumnIndex:i];
            
            if (![object isKindOfClass:[NSNull class]]){
                [valuesForColums setObject:object forKey:column];
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

        [self encodingRootObjectBlock:^{
            [NSInvocation invokeTarget:rootObject withSelector:@selector(encodeWithDBCoder:) ofClass:objectClass arg:self];
        }];
        
        rootObjectClass = NSStringFromClass(objectClass);
        pkColumnKey = [NSInvocation resultOfInvokingTarget:rootObject withSelector:@selector(dbPKProperty) ofClass:objectClass];
        pkColumnValue = [(NSObject *)rootObject valueForKey:pkColumnKey];
    }
    return self;
}

- (id) initWithDBObject:(id<DBCoding>) rootObject{
    return [self initWithDBObject:rootObject as:[rootObject class]];
}

//Be sure that pkColumn set before calling this method
- (void) encodingRootObjectBlock:(void(^)(void)) block{
    
    valuesForColums = [NSMutableDictionary new];
    classesForColumns = [NSMutableDictionary new];
    
    if (block) block();
    
    if (pkColumnName){
        /* To not duplicate pkColumn values-keys */
        [valuesForColums removeObjectForKey:pkColumnName];
    }
    
    colums = [valuesForColums allKeys];
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
    NSMutableArray * arguments = [[NSMutableArray alloc] initWithCapacity:colums.count];
    
    __block int columsToUpdate = 0;
    void(^addColumn)(NSString * column, id value) = ^(NSString * column, id value){
        BOOL isFirst = columsToUpdate == 0;
        [query appendFormat:@"%@ %@ = ?",isFirst?@"":@",",column];
        [arguments addObject:value];
        columsToUpdate++;
    };
    
    int keys_count = colums.count;
    for (NSString * key in colums){
       
        id object = valuesForColums[key];
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
    
    NSMutableArray * arguments = [[NSMutableArray alloc] initWithCapacity:colums.count];
    NSMutableString * query = [[NSMutableString alloc] initWithFormat:@"INSERT%@ INTO %@(",replace?@" OR REPLACE":@"",table];
    
    __block int columsToInsert = 0;
    void(^addColumn)(NSString * column, id value) = ^(NSString * column, id value){
        BOOL isFirst = columsToInsert == 0;
        [query appendFormat:@"%@%@", isFirst ? @"":@", ",column];
        [arguments addObject:value];
        columsToInsert++;
    };
    
    BOOL insertPK = [self havePrimaryKey];
    int keys_count = colums.count;
    
    if (insertPK){
        addColumn(pkColumnName, pkColumnValue);
    }
    
    for (NSString * key in colums){

        id object = valuesForColums[key];

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

- (void) enumerateToOneRelatedObjects:(DBInsertingBlock)block{
    
    for (NSString * column in colums) {
        
        Class objectClass = nil;
        id object = valuesForColums[column];
        
        
        /* If it is db object */
        if ([object conformsToProtocol:@protocol(DBCoding)]){
            /* Use Class from classesForColumns if exist or use object's class instead */
            objectClass = NSClassFromString(classesForColumns[column]);
            if (!objectClass) objectClass = [object class];

            /* save object in db by calling block */
            id insertedId = block(object, objectClass);
            if (insertedId){
                NSString * objectPKProperty = [NSInvocation resultOfInvokingTarget:object withSelector:@selector(dbPKProperty) ofClass:objectClass];
                /* notify object about inserted id */
                [object setValue:insertedId forKey:objectPKProperty];
                /* replace db object value with his id */
                valuesForColums[column] = insertedId;
            }else{
                [valuesForColums removeObjectForKey:column];
            }
            
        }
    }
}

- (void) enumerateToManyRelationCoders:(void(^)(DBCoder * connection_coder))block{
    [relatedCoders enumerateObjectsUsingBlock:^(DBCoder * coder, NSUInteger idx, BOOL *stop) {
        if (block) block(coder);
    }];
}

- (Class) rootObjectClass{
    return NSClassFromString(rootObjectClass);
}

@end
