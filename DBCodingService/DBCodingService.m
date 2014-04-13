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
    [coder enumerateOneToOneRelatedObjects:^id(id object, id<DBScheme> scheme, NSString *column) {
        __block id insertedId = nil;
        
        [self save:object withScheme:scheme mode:DBModeAll completion:^(BOOL wasInserted, id objectId, NSError *error) {
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
    __block id<DBScheme> objectsScheme = nil;
    
    NSArray *allKeys = [coder allOneToManyForeignKeys];
    
    for (NSString *foreignKey in allKeys)
    {
        [coder enumerateOneToManyRelatedObjectsForKey:foreignKey withBlock:^(id object, id<DBScheme>scheme) {
            objectsScheme = scheme;
            DBCoder *coder = [[DBCoder alloc] initWithObject:object scheme:scheme];
            [coder encodeObject:objectId forColumn:foreignKey];
            
            [self saveCoder:coder mode:DBModeAll completion:^(BOOL wasInserted, id insertedObjectId, NSError *error) {
                if (wasInserted) {
                    [scheme setPrimaryKeyValue:insertedObjectId forObject:object];
                }
                if (error){
                    NSLog(@"%@",[error localizedDescription]);
                }
                [savedIdentifiers addObject:insertedObjectId];
            }];
        }];
        if (objectsScheme) {
            NSString *idsPlaceholder = StringWithSqliteArgumentPlaceholder([savedIdentifiers count]);
            [self deleteOneToManyObjectsWithScheme:objectsScheme withForeignKey:foreignKey where:[NSString stringWithFormat:@"%@ NOT IN (%@)",[objectsScheme primaryKeyColumn], idsPlaceholder] args:savedIdentifiers];
        }
        [savedIdentifiers removeAllObjects];
        objectsScheme = nil;
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
        NSArray *connectionDecoders = [self decodersWithScheme:nil fromSQLQuery:query withArgs:@[encoderId]];
        NSMutableDictionary *connectionDecodersDict = [[NSMutableDictionary alloc] initWithCapacity:[connectionDecoders count]];
        for (DBCoder *decoder in connectionDecoders) {
            id encodedObjectId = [decoder decodeObjectForColumn:connection.encodedObjectColumn];
            connectionDecodersDict[encodedObjectId] = decoder;
        }
        __block id<DBScheme> encodedObjectScheme = nil;
        id<DBScheme>connectionScheme = [[connection class] scheme];
        
        [coder enumerateManyToManyCodersForConnection:connection usingBlock:^(DBCoder *connectionCoder) {
            id encodedObject = [connectionCoder decodeObjectForColumn:connection.encodedObjectColumn];
            
            if (!encodedObjectScheme) {
                encodedObjectScheme = [[encodedObject class] scheme];
            }
            
            id encodedObjectId = [encodedObjectScheme primaryKeyValueFromObject:encodedObject];
            
            if (encodedObjectId) {
                //get existing relation Id for relation with current Ids pair
                DBCoder *existingCoder = connectionDecodersDict[encodedObjectId];
                
                NSString *primaryKeyColumn = [connectionScheme primaryKeyColumn];
                
                [connectionCoder encodeObject:[existingCoder decodeObjectForColumn:primaryKeyColumn] forColumn:primaryKeyColumn];
            }
            [connectionCoder encodeObject:encoderId forColumn:connection.encoderColumn];
            [self saveCoder:connectionCoder mode:DBModeAll completion:nil];

            //delete decoders which was overwrited
            if (encodedObjectId != dbPrimaryKeyUndefined) {
                [connectionDecodersDict removeObjectForKey:encodedObjectId];
            }
        }];
        
        if ([[coder scheme] deleteRuleForManyToManyRelationWithConnection:connection] == DBSchemeDeleteRuleCascade) {
            NSArray *connectionDecodersToDelete = [connectionDecodersDict allValues];
            for (DBCoder *connectionCoder in connectionDecodersToDelete) {
                [[connectionCoder scheme] setParentScheme:[coder scheme]];
                id objectToDelete = [connectionCoder decodeObjectWithScheme:encodedObjectScheme forColumn:connection.encodedObjectColumn];
                [connectionCoder encodeObject:objectToDelete forColumn:connection.encodedObjectColumn];
                [self delete:connectionCoder error:nil];
            }
        }
    }
}

- (void)save:(id)object withScheme:(id<DBScheme>)scheme mode:(DBMode)mode completion:(DBSaveCompletion)completion
{
    if (!object){
        NSError * error = [NSError errorWithCode:DBErrorCodeObjectIsNil description:@"Object to save can't be nil"];
        if (completion) completion(0, dbPrimaryKeyUndefined, error);
        return;
    }
    
    DBCoder *coder = [[DBCoder alloc] initWithObject:object scheme:scheme];
    
    [self saveCoder:coder mode:mode completion:^(BOOL wasInserted, id objectId, NSError *error) {
       
        if (wasInserted) {
            /* Set just inserted primary key */
            [scheme setPrimaryKeyValue:objectId forObject:object];
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
        objectId = [coder primaryKeyToEncode] ? [coder primaryKeyToEncode] : insertedId;
    } else {
        [self update:coder error:&error];
        objectId = [coder primaryKeyToEncode];
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


- (void) save:(id<DBCoding>) object completion:(DBSaveCompletion)completion{
    [self save:object withScheme:[[object class] scheme] mode:DBModeAll completion:completion];
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
    
    if ([coder primaryKeyToEncode]){
        id existingObject = [self objectWithId:[coder primaryKeyToEncode] andScheme:[coder scheme]];
        isExist = (existingObject != nil);
    }
    
    return isExist;
}

- (id)objectWithScheme:(id<DBScheme>)scheme fromDecoder:(DBCoder *)decoder
{
    id object = nil;
    if (scheme && decoder) {
        object = [scheme decodeObject:object fromCoder:decoder];
    }
    return object;
}

- (id) objectOfClass:(Class) objectClass fromDecoder:(DBCoder *) decoder{    
    return [self objectOfClass:objectClass withSchemeClass:objectClass fromDecoder:decoder];
}

- (id)objectWithId:(id)identifier andScheme:(id<DBScheme>)scheme
{
    if (!identifier) {
        NSLog(@"You are trying to fetch object of %@ scheme with nil id.", scheme);
        return nil;
    }
    
    NSString *table = [scheme table];
    NSString *primaryKey = [scheme primaryKeyColumn];
    
    NSString *query = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ = ? LIMIT 1", table, primaryKey];
    
    NSArray *decoders = [self decodersWithScheme:scheme fromSQLQuery:query withArgs:@[identifier]];
    
    id<DBCoding> object = nil;
    
    if ([decoders count] > 0){
        object = [self objectWithScheme:scheme fromDecoder:[decoders firstObject]];
    }
    
    return object;
}


- (id) reloadObject:(id<DBCoding>) object
{
    if (!object) {
        NSLog(@"Object to reload can't be nil");
        return nil;
    }
    
    id identifier = [(NSObject *)object valueForKey:[object dbPKProperty]];
    
    return [self objectWithId:identifier andScheme:[[object class] scheme]];
}

- (NSArray *)decodersWithScheme:(id<DBScheme>)scheme fromSQLQuery:(NSString *)query withArgs:(NSArray *) args
{
    if (!query) {
        NSLog(@"Query to fetch decoders can't be nil");
        return nil;
    }
    
    NSMutableArray * resultArray = [[NSMutableArray alloc] init];
   
    [self performBlock:^(FMDatabase *db) {
        FMResultSet * resultSet = [db executeQuery:query withArgumentsInArray:args];

        while ([resultSet next]) {
            DBCoder * decoder = [[DBCoder alloc] initWithResultSet:resultSet scheme:scheme dbService:self];
            [resultArray addObject:decoder];
        }
        
        [resultSet close];
    }];
    
    return resultArray;
}

- (NSArray *)objectsWithScheme:(id<DBScheme>)scheme fromSQLQuery:(NSString *)query withArgs:(NSArray *)args;
{
    NSParameterAssert(scheme);
    
    NSArray *decoders = [self decodersWithScheme:scheme fromSQLQuery:query withArgs:args];
    NSMutableArray *objects = [[NSMutableArray alloc] initWithCapacity:[decoders count]];
    for (DBCoder *decoder in decoders) {
        id object = [self objectWithScheme:scheme fromDecoder:decoder];
        [objects addObject:object];
    }
    return objects;
}

- (id)latestPrimaryKeyForScheme:(id<DBScheme>)scheme;
{
    __block id primaryKey = nil;
    
    NSString *query = [NSString stringWithFormat:@"SELECT %@ from %@ ORDER BY %@ DESC LIMIT 1",[scheme primaryKeyColumn],[scheme table],[scheme primaryKeyColumn]];
    [self performBlock:^(FMDatabase *db) {
        FMResultSet *resultSet = [db executeQuery:query];
        primaryKey = [resultSet objectForColumnName:[scheme primaryKeyColumn]];
    }];
    
    return primaryKey;
}

- (void)delete:(DBCoder *)coder error:(NSError **)error where:(NSString *)whereQuery args:(NSArray *)arguments
{
    //Remove arrays of objects which refers to current via connection table
    [coder enumerateManyToManyRelationCoders:^(DBCoder *connection_coder, DBTableConnection *connection) {
        if ([[coder scheme] deleteRuleForManyToManyRelationWithConnection:connection] == DBSchemeDeleteRuleCascade) {
            [[connection_coder scheme] setParentScheme:[coder scheme]];
            NSString *query = [NSString stringWithFormat:@"WHERE %@ IS ?",connection.encoderColumn];
            NSArray *args = @[[coder decodeObjectForColumn:[[coder scheme] primaryKeyColumn]]];
            [self delete:connection_coder error:error where:query args:args];
        }
    }];
    
    //Remove arrays of objects which refers to current
    [coder enumerateOneToManyRelatedObjects:^(id object, id<DBScheme> scheme, NSString *foreignKey) {
        if ([[coder scheme] deleteRuleForOneToManyRelatedObjectWithScheme:scheme connectedOnForeignColumn:foreignKey] == DBSchemeDeleteRuleCascade) {
            DBCoder *foreignCoder = [[DBCoder alloc] initWithObject:object scheme:scheme];
            [self delete:foreignCoder error:error];
        }
    }];
    
    //Remove object that refers to current
    [coder enumerateOneToOneRelatedObjects:^id(id object, id<DBScheme> scheme, NSString *column) {
        if ([[coder scheme] deleteRuleForOneToOneRelatedObjectWithScheme:scheme forColumn:column] == DBSchemeDeleteRuleCascade) {
            DBCoder *relatedCoder = [[DBCoder alloc] initWithObject:object scheme:scheme];
            [self delete:relatedCoder error:error];
        }
        return nil;
    }];
    
    if (!error || !*error) {
        
        NSString *table = [[coder scheme] table];
        
        NSString *query = [NSString stringWithFormat:@"DELETE FROM %@ %@",table, whereQuery];
        
        BOOL success = [self executeUpdate:query withArgumentsInArray:arguments];
        
        if (error && !success){
            [self setupDBError:error action:@"deleting from db"];
        }
        
    }
}

- (void)delete:(DBCoder *)coder error:(NSError **)error
{
    id primaryKeyValue = [[coder scheme] primaryKeyColumn];
    [self delete:coder error:error where:[NSString stringWithFormat:@"WHERE %@ = ?",primaryKeyValue]  args:@[[coder decodeObjectForColumn:primaryKeyValue]]];
}

- (void)deleteObject:(id)object withScheme:(id<DBScheme>)scheme completion:(DBDeleteCompletion)completion
{
    NSError *error = nil;
    
    if (object) {
        DBCoder *coder = [[DBCoder alloc] initWithObject:object scheme:scheme];
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

- (void)deleteObject:(id<DBCoding>)object completion:(DBDeleteCompletion) completion
{
    [self deleteObject:object withScheme:[[object class] scheme] completion:completion];
}

- (void)deleteOneToManyObjectsWithScheme:(id<DBScheme>)scheme withForeignKey:(NSString *)foreignKey where:(NSString *)whereQuery args:(NSArray *)args
{
    NSString *selectQuery = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@",[scheme table], whereQuery];
    NSArray *decoders = [self decodersWithScheme:scheme fromSQLQuery:selectQuery withArgs:args];
    for (DBCoder *decoder in decoders) {
        NSError *error = nil;        
        [self delete:decoder error:&error];
    }
}

@end



