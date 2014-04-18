//
//  QliqDBService.m
//  qliq
//
//  Created by Aleksey Garbarev on 12/3/12.
//
//

#import "DBCodingService.h"
#import "DBCoder_DBService.h"
#import "NSInvocation_Class.h"

#import "FMDatabase.h"
#import "FMDatabaseQueue.h"
#import "DBCoding.h"

@interface NSError(NSError_Shortcuts)

+ (NSError *) errorWithCode:(NSInteger) code description:(NSString *) description;

@end

@implementation NSError (NSError_Shortcuts)

+ (NSError *) errorWithCode:(NSInteger) code description:(NSString *) description{
    return [NSError errorWithDomain:@"com.dbcodingservice" code:code userInfo: @{ NSLocalizedDescriptionKey : description} ];
}

@end

static NSString *StringWithSqliteArgumentPlaceholder(NSInteger numberOfArguments)
{
    NSMutableString *placeholder = [NSMutableString new];
    for (int i = 0; i < numberOfArguments; i++) {
        if (i < numberOfArguments - 1) {
            [placeholder appendString:@"?, "];
        } else {
            [placeholder appendString:@"?"];
        }
    }
    return placeholder;
}

@interface DBCodingService()


@end

@implementation DBCodingService {
    FMDatabase *database;
    FMDatabaseQueue *queue;
}

- (id) initWithDatabase:(FMDatabase *) _database
{
    self = [super init];
    if (self) {
        database = _database;
    }
    return self;
}

- (id)initWithDatabaseQueue:(FMDatabaseQueue *)_queue
{
    self = [super init];
    if (self) {
        queue = _queue;
    }
    return self;
}

#pragma mark - Working with FMDB

- (void)performBlock:(void(^)(FMDatabase *db))block
{
    if (queue) {
        [queue inDatabase:block];
    } else if (database) {
        block(database);
    } else {
        NSLog(@"Database is not set. Init with 'initWithQueue' or 'initWithDatabase'.");
    }
}

- (BOOL)executeUpdate:(NSString *)query withArgumentsInArray:(NSArray *)args
{
    __block BOOL success;
    [self performBlock:^(FMDatabase *db) {
        success = [db executeUpdate:query withArgumentsInArray:args];
    }];
    return success;
}

- (NSError *)lastError
{
    __block NSError *error;
    [self performBlock:^(FMDatabase *db) {
        error = [db lastError];
    }];
    return error;
}

- (sqlite_int64)lastInsertRowId
{
    __block sqlite_int64 lastRowId;
    [self performBlock:^(FMDatabase *db) {
        lastRowId = [db lastInsertRowId];
    }];
    return lastRowId;
}

#pragma mark - Changing DB

- (void)removeObjectsInCoder:(DBCoder *)coder
{
    [coder enumerateOneToOneRelatedObjects:^id(id<DBCoding> object, Class objectClass, NSString *column) {
        return nil;
    }];
}

//Saving one-to-one relations
- (void)replaceObjectsByIdsInCoder:(DBCoder *)coder
{
    //replace all db object with it's ids
    [coder enumerateOneToOneRelatedObjects:^id(id<DBCoding> object, Class objectClass, NSString *column) {
        __block id insertedId = nil;
        
        [self save:object withSchemeClass:objectClass completion:^(BOOL wasInserted, id objectId, NSError *error) {
            insertedId = objectId;
            if (error){
                NSLog(@"%@",[error localizedDescription]);
            }
        }];
        
        return insertedId;
    }];
}

//Saving one-to-many relations
- (void)saveOneToManyWithId:(id)objectId inCoder:(DBCoder *)coder
{
    NSMutableArray *savedIdentifiers = [NSMutableArray new];
    __block Class objectsClass = nil;
    
    NSArray *allKeys = [coder allOneToManyForeignKeys];
    
    for (NSString *foreignKey in allKeys)
    {
        [coder enumerateOneToManyRelatedObjectsForKey:foreignKey withBlock:^(id<DBCoding> object) {
            objectsClass = [object class];
            DBCoder *coder = [[DBCoder alloc] initWithDBObject:object as:[object class]];
            [coder encodeObject:objectId forColumn:foreignKey];
            
            [self saveCoder:coder mode:DBModeAll completion:^(BOOL wasInserted, id objectId, NSError *error) {
                if (wasInserted) {
                    [self setPrimaryKey:objectId forObject:object asClass:[object class]];
                }
                if (error){
                    NSLog(@"%@",[error localizedDescription]);
                }
                [savedIdentifiers addObject:objectId];
            }];
        }];
        if (objectsClass) {
            NSString *idsPlaceholder = StringWithSqliteArgumentPlaceholder([savedIdentifiers count]);
            [savedIdentifiers insertObject:objectId atIndex:0];
            [self deleteOneToManyObjectsOfClass:objectsClass withForeignKey:foreignKey where:[NSString stringWithFormat:@"%@ = ? AND %@ NOT IN (%@)", foreignKey, [objectsClass dbPKColumn], idsPlaceholder] args:savedIdentifiers];
        }
        [savedIdentifiers removeAllObjects];
        objectsClass = nil;
    }
}

//TODO:REFACTOR!!
//Saving handle many-to-many relations
- (void)saveManyToManyWithId:(id)encoderId inCoder:(DBCoder *)coder
{
    NSArray *connections = [coder allManyToManyConnections];
    
    for (DBTableConnection *connection in connections)
    {
        NSString *query = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ = ?",connection.table, connection.encoderColumn];
        NSArray *connectionDecoders = [self decodersFromSQLQuery:query withArgs:@[encoderId]];
        NSMutableDictionary *connectionDecodersDict = [[NSMutableDictionary alloc] initWithCapacity:[connectionDecoders count]];
        for (DBCoder *decoder in connectionDecoders) {
            id encodedObjectId = [decoder decodeObjectForColumn:connection.encodedObjectColumn];
            connectionDecodersDict[encodedObjectId] = decoder;
        }
        __block Class encodedObjectClass = nil;
        
        [coder enumerateManyToManyCodersForConnection:connection usingBlock:^(DBCoder *connectionCoder) {
            id encodedObject = [connectionCoder decodeObjectForColumn:connection.encodedObjectColumn];
            if (!encodedObjectClass) {
                encodedObjectClass = [encodedObject class];
            }
            id encodedObjectId = [encodedObject valueForKey:[encodedObject dbPKProperty]];
            if (encodedObjectId != dbPrimaryKeyUndefined) {
                //get existing relation Id for relation with current Ids pair
                DBCoder *existingCoder = connectionDecodersDict[encodedObjectId];
                [connectionCoder setPrimaryKeyColumn:connection.relationPKColumn];
                [connectionCoder setPrimaryKey:[existingCoder decodeObjectForColumn:connection.relationPKColumn]];
            }
            [connectionCoder encodeObject:encoderId forColumn:connection.encoderColumn];
            [self saveCoder:connectionCoder mode:DBModeAll completion:nil];

            //delete decoders which was overwrited
            if (encodedObjectId != dbPrimaryKeyUndefined) {
                [connectionDecodersDict removeObjectForKey:encodedObjectId];
            }
        }];
        
        NSArray *connectionDecodersToDelete = [connectionDecodersDict allValues];
        for (DBCoder *decoder in connectionDecodersToDelete) {
            id objectToDelete = [decoder decodeObjectOfClass:encodedObjectClass forColumn:connection.encodedObjectColumn];
            [decoder encodeObject:objectToDelete forColumn:connection.encodedObjectColumn];
            [decoder setPrimaryKey:[decoder decodeObjectForColumn:connection.relationPKColumn]];
            [decoder setPrimaryKeyColumn:connection.relationPKColumn];
            [self deleteConnectionCoder:decoder withConnection:connection encoderCoder:coder];
        }
    }
}

- (void)save:(id<DBCoding>) object withSchemeClass:(Class)objectClass mode:(DBMode) mode completion:(DBSaveCompletion)completion
{
    if (!object){
        NSError * error = [NSError errorWithCode:DBErrorCodeObjectIsNil description:@"Object to save can't be nil"];
        if (completion) completion(0, dbPrimaryKeyUndefined, error);
        return;
    }
    
    DBCoder * coder = [[DBCoder alloc] initWithDBObject:object as:objectClass];
    
    [self saveCoder:coder mode:mode completion:^(BOOL wasInserted, id objectId, NSError *error) {
       
        if (wasInserted) {
            /* Set Primary Key */
            [self setPrimaryKey:objectId forObject:object asClass:objectClass];
        }
        
        if (completion) {
            completion(wasInserted, objectId, error);
        }
    }];
}

- (void)saveCoder:(DBCoder *)coder mode:(DBMode)mode completion:(DBSaveCompletion)completion
{
    BOOL wasInserted = NO;
    id objectId = nil;
    NSError * error = nil;
    
    if (mode & DBModeOneToOne){
        [self replaceObjectsByIdsInCoder:coder];
    }else{
        [self removeObjectsInCoder:coder];
    }
    
    if (![self isExistCoder:coder]) {
        wasInserted = YES;
        NSNumber * insertedId = [self insert:coder update:NO error:&error];
        objectId = [coder havePrimaryKey] ? [coder primaryKey] : insertedId;
    } else {
        [self update:coder error:&error];
        objectId = [coder primaryKey];
    }
    
    if (mode & DBModeManyToMany){
        [self saveManyToManyWithId:objectId inCoder:coder];
    }
    if (mode & DBModeOneToMany){
        [self saveOneToManyWithId:objectId inCoder:coder];
    }
    
    if (completion) {
        completion(wasInserted, objectId, error);
    }
}

- (void) save:(id<DBCoding>) object withSchemeClass:(Class)objectClass completion:(DBSaveCompletion)completion{
    [self save:object withSchemeClass:objectClass mode:DBModeAll completion:completion];
}

- (void) save:(id<DBCoding>) object completion:(DBSaveCompletion)completion{
    [self save:object withSchemeClass:[object class] mode:DBModeAll completion:completion];
}

- (NSNumber *) insert:(DBCoder *) coder update:(BOOL) shouldUpdate error:(NSError **) error{
    
    __block NSNumber * insertedId = nil;
    
    [coder insertStatement:^(NSString *query, NSArray *args) {
        
        BOOL success = NO;
        
        if (query && args) {
            success = [self executeUpdate:query withArgumentsInArray:args];
            insertedId = [NSNumber numberWithLongLong:[self lastInsertRowId]];
        }
        
        if (error && !success){
            [self setupDBError:error action:@"inserting to db" query:query args:args];
        }
        
    } replace:shouldUpdate];
        
    return insertedId;
}

- (void) update:(DBCoder *) coder error:(NSError **) error
{
    [coder updateStatement:^(NSString *query, NSArray *args) {
        BOOL success = NO;
        
        if (query && args){
            success = [self executeUpdate:query withArgumentsInArray:args];
        }
        
        if (error && !success){
            [self setupDBError:error action:@"updating db"];
        }
    }];
}

- (void) setupDBError:(NSError **) error action:(NSString *) action
{
    NSError * dbError = [self lastError];
    if (dbError){
        * error = dbError;
    }else{
        * error = [NSError errorWithCode:DBErrorCodeUnknown description:[NSString stringWithFormat:@"Something gone wrong while %@",action]];
    }
}

- (void) setupDBError:(NSError **) error action:(NSString *) action query:(NSString *) query args:(NSArray *) args
{
    NSError * dbError = [self lastError];
    if (dbError){
        * error = dbError;
    }else{
        * error = [NSError errorWithCode:DBErrorCodeUnknown description:[NSString stringWithFormat:@"Something gone wrong while %@.\nQuery: %@\nArgs: %@",action,query,args]];
    }
}


#pragma mark - Access to DB

- (BOOL)isExistCoder:(DBCoder *)coder
{
    BOOL isExist = NO;
    
    if (![coder connection] && [coder havePrimaryKey]){
        id existingObject = [self objectWithId:[coder primaryKey] andClass:[coder rootObjectClass]];
        isExist =  (existingObject != nil);
    } else if ([coder connection] && [coder primaryKey]) {
        DBTableConnection *connection = [coder connection];
        NSString * query = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ = ? LIMIT 1",connection.table, connection.relationPKColumn];
        isExist = [[self decodersFromSQLQuery:query withArgs:@[[coder primaryKey]]] count] > 0;
    }
    
    return isExist;
}

- (BOOL) isExist:(id<DBCoding>) object{
    
    BOOL isExist = NO;
    
    id pkValue = [(NSObject *)object valueForKey:[object dbPKProperty]];
    BOOL isCorrect = [DBCoder isCorrectPrimaryKey:pkValue];
    
    if (isCorrect){
        id existObject = [self objectWithId:[(NSObject *)object valueForKey:[object dbPKProperty]] andClass:[object class]];
        isExist =  (existObject != nil);
    }
    
    return isExist;
}

- (void) setPrimaryKey:(id) key forObject:(id) object asClass:(Class) asClass{
    NSString * pkProperty = [NSInvocation resultOfInvokingTarget:object withSelector:@selector(dbPKProperty) ofClass:asClass];
    [(NSObject *)object setValue:key forKey:pkProperty];
}

- (id) objectOfClass:(Class) objectClass withSchemeClass:(Class) asClass fromDecoder:(DBCoder *) decoder{
  
    id<DBCoding> object = nil;
    if (objectClass && decoder)
    {
        NSString * pkColumn = [asClass dbPKColumn];
        id pkValue = [decoder decodeObjectForColumn:pkColumn];
        
        /* Set primary key for decoder */
        [decoder setPrimaryKey:pkValue];
        
        /* Init with decoder */
        object = [NSInvocation resultOfInvokingTarget:[objectClass alloc] withSelector:@selector(initWithDBCoder:) ofClass:asClass arg:decoder];
        
        /* Set primary key for initialized instance */
        [self setPrimaryKey:pkValue forObject:object asClass:asClass];
    }
    return object;
}

- (id) objectOfClass:(Class) objectClass fromDecoder:(DBCoder *) decoder{    
    return [self objectOfClass:objectClass withSchemeClass:objectClass fromDecoder:decoder];
}

- (id)objectWithId:(id)identifier andClass:(Class)objectClass withSchemeClass:(Class)asClass{
    
    if (!identifier) {
        NSLog(@"You are trying to fetch object of %@ class with nil id.",objectClass);
        return nil;
    }
    
    NSString * table = [asClass dbTable];
    NSString * primaryKey = [asClass dbPKColumn];
    
    NSString * query = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ = ? LIMIT 1",table,primaryKey];
    
    NSArray * decoders = [self decodersFromSQLQuery:query withArgs:@[identifier]];
    
    id <DBCoding> object = nil;
    
    if ([decoders count] > 0){
        object = [self objectOfClass:objectClass withSchemeClass:asClass fromDecoder:decoders[0]];
    }
    
    return object;
}

- (id) objectWithId:(id) identifier andClass:(Class) objectClass{
    return [self objectWithId:identifier andClass:objectClass withSchemeClass:objectClass];
}

- (id) reloadObject:(id<DBCoding>) object{
    
    if (!object) {
        NSLog(@"Object to reload can't be nil");
        return nil;
    }
    
    id identifier = [(NSObject *)object valueForKey:[object dbPKProperty]];
    
    return [self objectWithId:identifier andClass:[object class]];
    
}

- (NSArray *)decodersFromSQLQuery:(NSString *) query withArgs:(NSArray *) args
{
    if (!query) {
        NSLog(@"Query to fetch decoders can't be nil");
        return nil;
    }
    
    NSMutableArray * resultArray = [[NSMutableArray alloc] init];
   
    [self performBlock:^(FMDatabase *db) {
        FMResultSet * resultSet = [db executeQuery:query withArgumentsInArray:args];

        while ([resultSet next]) {
            DBCoder * decoder = [[DBCoder alloc] initWithResultSet:resultSet dbService:self];
            [resultArray addObject:decoder];
        }
        
        [resultSet close];
    }];
    
    return resultArray;
}

- (NSArray *)objectsOfClass:(Class)objectClass fromSQLQuery:(NSString *)query withArgs:(NSArray *)args
{
    if (![objectClass conformsToProtocol:@protocol(DBCoding)]) {
        NSLog(@"You trying to fetch objects of class whicn not confirms DBCoding");
        return nil;
    }
    
    NSArray *decoders = [self decodersFromSQLQuery:query withArgs:args];
    NSMutableArray *objects = [[NSMutableArray alloc] initWithCapacity:[decoders count]];
    for (DBCoder *decoder in decoders) {
        id object = [self objectOfClass:objectClass fromDecoder:decoder];
        [objects addObject:object];
    }
    return objects;
}

- (id)latestPrimaryKeyForClass:(Class)objectClass
{
    id primaryKey = nil;
    
    NSString * primaryKeyColumn = [objectClass dbPKColumn];
    NSString * tableName = [objectClass dbTable];
    NSString * query = [NSString stringWithFormat:@"SELECT %@ from %@ ORDER BY %@ DESC LIMIT 1",primaryKeyColumn,tableName,primaryKeyColumn];
    NSArray * decoders = [self decodersFromSQLQuery:query withArgs:nil];
    if (decoders.count > 0){
        primaryKey = [decoders[0] decodeObjectForColumn:primaryKeyColumn];
    }
    
    return primaryKey;
}

- (void)deleteConnectionCoder:(DBCoder *)coder withConnection:(DBTableConnection *)connection encoderCoder:(DBCoder *)parentCoder
{
    [coder enumerateOneToOneRelatedObjects:^id(id<DBCoding> object, __unsafe_unretained Class objectClass, NSString *column) {
        if ([self shouldDeleteObjectWithClass:[object class] forConnection:connection onEncoderClass:[parentCoder rootObjectClass]]) {
            DBCoder *relatedCoder = [[DBCoder alloc] initWithDBObject:object as:objectClass];
            NSError *error;
            [self delete:relatedCoder error:&error];
        }
        return nil;
    }];

    [coder setTable:connection.table];
    [coder deleteStatement:^(NSString *query, NSArray *args) {
        BOOL success = NO;
        if (query && args){
            success = [self executeUpdate:query withArgumentsInArray:args];
        }
    }];
}

- (void)delete:(DBCoder *)coder error:(NSError **)error
{
    //Remove arrays of objects which refers to current via connection table
    [coder enumerateManyToManyRelationCoders:^(DBCoder *connection_coder, DBTableConnection *connection) {
        if ([self shouldDeleteConnection:connection forClass:[coder rootObjectClass]]) {
            [connection_coder setPrimaryKey:[coder primaryKey]];
            [connection_coder setPrimaryKeyColumn:connection.encoderColumn];
            [self deleteConnectionCoder:connection_coder withConnection:connection encoderCoder:coder];
        } else {
            NSLog(@"will not delete connection!");
        }
    }];
    
    //Remove arrays of objects which refers to current
    [coder enumerateOneToManyRelatedObjects:^(id<DBCoding> object, NSString *foreignKey) {
        if ([self shouldDeleteOneToManyObjectWithClass:[object class] forForeignColumn:foreignKey]) {
            DBCoder *foreignCoder = [[DBCoder alloc] initWithDBObject:object as:[object class]];
            [self delete:foreignCoder error:error];
        }
    }];
    
    //Remove object that refers to current
    [coder enumerateOneToOneRelatedObjects:^id(id<DBCoding> object, __unsafe_unretained Class objectClass, NSString *column) {
        if ([self shouldDeleteObjectWithClass:[object class] withClass:objectClass forColumn:column]) {
            DBCoder *relatedCoder = [[DBCoder alloc] initWithDBObject:object as:objectClass];
            [self delete:relatedCoder error:error];
        }
        return nil;
    }];
    
    if (!*error){
        [coder deleteStatement:^(NSString *query, NSArray *args) {
            BOOL success = NO;
            
            if (query && args){
                success = [self executeUpdate:query withArgumentsInArray:args];
            }
            
            if (error && !success){
                [self setupDBError:error action:@"deleting from db"];
            }
        }];
    }
}

- (void)deleteObject:(id<DBCoding>)object withSchemeClass:(Class)schemeClass completion:(DBDeleteCompletion)completion
{
    NSError *error = nil;
    
    if (object) {
        DBCoder *coder = [[DBCoder alloc] initWithDBObject:object as:schemeClass];
        if ([self isExistCoder:coder]) {
            [self delete:coder error:&error];
        } else {
            error = [NSError errorWithCode:DBErrorCodeObjectIsNotExist description:@"Object not exist. Nothing to delete."];
        }
    } else {
        error = [NSError errorWithCode:DBErrorCodeObjectIsNil description:@"Object to delete can't be nil"];
    }
    
    if (completion) {
        completion(error);
    }
}

- (void)deleteObject:(id<DBCoding>) object completion:(DBDeleteCompletion) completion
{
    [self deleteObject:object withSchemeClass:[object class] completion:completion];
}

- (void)deleteOneToManyObjectsOfClass:(Class<DBCoding>)objectClass withForeignKey:(NSString *)foreignKey where:(NSString *)whereQuery args:(NSArray *)args
{
    if ([self shouldDeleteOneToManyObjectWithClass:objectClass forForeignColumn:foreignKey]) {
        NSString *selectQuery = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@",[objectClass dbTable], whereQuery];
        NSArray *decoders = [self decodersFromSQLQuery:selectQuery withArgs:args];
        for (DBCoder *decoder in decoders) {
            NSError *error = nil;
            [decoder setTable:[objectClass dbTable]];
            [decoder setPrimaryKeyColumn:[objectClass dbPKColumn]];
            [decoder setPrimaryKey:[decoder decodeObjectForColumn:[objectClass dbPKColumn]]];
            [decoder setRootObjectClass:objectClass];
            
            [self delete:decoder error:&error];
        }
    }
}

#pragma mark -

- (BOOL)shouldDeleteObjectWithClass:(Class)objectClass withClass:(Class)class forColumn:(NSString *)column
{
    BOOL shouldDelete = YES;

    SEL selector = @selector(dbShouldDeleteOneToOneRelatedObjectWithClass:forColumn:);
    if ([class respondsToSelector:selector]) {
        shouldDelete = [NSInvocation boolOfInvokingTarget:class withSelector:selector ofClass:class arg:objectClass arg:column];
    }
    return shouldDelete;
}

- (BOOL)shouldDeleteOneToManyObjectWithClass:(Class)objectClass forForeignColumn:(NSString *)column
{
    BOOL shouldDelete = YES;
    
    SEL selector = @selector(dbShouldDeleteOneToManyRelatedObjectWithClass:connectedOnForeignColumn:);
    if ([objectClass respondsToSelector:selector]) {
        shouldDelete = [NSInvocation boolOfInvokingTarget:objectClass withSelector:selector ofClass:objectClass arg:objectClass arg:column];
    }
    return shouldDelete;
}

- (BOOL)shouldDeleteConnection:(DBTableConnection *)connection forClass:(Class)objectClass
{
    BOOL shouldDelete = YES;
    
    SEL selector = @selector(dbShouldDeleteManyToManyRelationWithConnection:);
    if ([objectClass respondsToSelector:selector]) {
        shouldDelete = [NSInvocation boolOfInvokingTarget:objectClass withSelector:selector ofClass:objectClass arg:connection];
    }
    return shouldDelete;
}

- (BOOL)shouldDeleteObjectWithClass:(Class)objectClass forConnection:(DBTableConnection *)connection onEncoderClass:(Class)encoderClass
{
    BOOL shouldDelete = NO;

    SEL selector = @selector(dbShouldDeleteManyToManyRelatedObjectWithClass:withConnection:);
    if ([encoderClass respondsToSelector:selector]) {
        shouldDelete = [NSInvocation boolOfInvokingTarget:encoderClass withSelector:selector ofClass:encoderClass arg:objectClass arg:connection];
    }
    return shouldDelete;
}

@end



