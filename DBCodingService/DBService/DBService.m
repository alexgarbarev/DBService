//
//  DBService.m
//  DBCodingServiceExample
//
//  Created by Aleksey Garbarev on 16.04.14.
//
//

#import "DBService.h"
#import "FMDatabaseQueue.h"
#import "DBEntity.h"
#import "DBEntityField.h"
#import "DBScheme.h"
#import "DBQueryBuilder.h"
#import "DBDatabaseProvider.h"
#import "DBObjectFetcher.h"
#import "DBObjectSaver.h"
#import "DBObjectDeleter.h"

@interface DBService ()

@property (nonatomic, strong) FMDatabaseQueue *queue;

@property (nonatomic, strong) DBScheme *scheme;
@property (nonatomic, strong) DBQueryBuilder *queryBuilder;
@property (nonatomic, strong) DBObjectFetcher *objectFetcher;
@property (nonatomic, strong) DBObjectSaver *objectSaver;
@property (nonatomic, strong) DBObjectDeleter *objectDeleter;

@end

@implementation DBService {
    DBDatabaseProvider *_provider;
}

- (instancetype)initWithDatabaseQueue:(FMDatabaseQueue *)queue scheme:(DBScheme *)scheme
{
    self = [super init];
    if (self) {
        self.queue = queue;
        self.scheme = scheme;
        [self commonDBServiceInit];
    }
    return self;
}

- (void)commonDBServiceInit
{
    self.queryBuilder = [[DBQueryBuilder alloc] initWithScheme:self.scheme];
    self.objectFetcher = [[DBObjectFetcher alloc] initWithScheme:self.scheme];
    self.objectSaver = [[DBObjectSaver alloc] initWithScheme:self.scheme];
    self.objectDeleter = [[DBObjectDeleter alloc] initWithScheme:self.scheme];
}

#pragma mark - Working with FMDB

- (void)executeBlock:(void(^)(DBDatabaseProvider *provider))block
{
    if (self.queue) {
        [self.queue inDatabase:^(FMDatabase *db) {
            if (!_provider) {
                _provider = [[DBDatabaseProvider alloc] initWithQueryBuilder:self.queryBuilder database:db];
            }
            block(_provider);
        }];
    } else {
        NSAssert(NO, @"Database is not set. Init with 'initWithDatabaseQueue:scheme:'.");
    }
}

#pragma mark - Saving

- (void)save:(id)object completion:(DBSaveCompletion)completion
{
    [self executeBlock:^(DBDatabaseProvider *provider) {
                
        DBEntity *entity = [self.scheme entityForClass:[object class]];
        
        [self.objectSaver save:object withEntity:entity provider:provider completion:completion];
    }];
}

#pragma mark - Fetches

- (id)fetchObjectWithId:(id)objectId andClass:(Class)objectClass
{
    return [self fetchObjectWithId:objectId andEntity:[self.scheme entityForClass:objectClass]];
}

- (NSArray *)fetchObjectsOfClass:(Class)objectClass fromSQLQuery:(NSString *)query withArgs:(NSArray *)args
{
    return [self fetchObjectsOfEntity:[self.scheme entityForClass:objectClass] fromSQLQuery:query withArgs:args];
}

- (id)fetchObjectWithId:(id)objectId andEntity:(DBEntity *)entity
{
    __block id object = nil;
    [self executeBlock:^(DBDatabaseProvider *provider) {
        object = [self.objectFetcher fetchObjectWithId:objectId entity:entity provider:provider];
    }];
    return object;
}

- (NSArray *)fetchObjectsOfEntity:(DBEntity *)entity fromSQLQuery:(NSString *)query withArgs:(NSArray *)args
{
    NSMutableArray *objects = [NSMutableArray new];
    
    [self executeBlock:^(DBDatabaseProvider *provider) {
        id<DBDatabaseResult> result = [provider resultFromQuery:query withArgs:args];
        while ([result next]) {
            id object = [self.objectFetcher fetchObjectFromResult:result entity:entity provider:provider];
            [objects addObject:object];
        }
        [result close];
    }];
    
    return objects;
}

- (id)reloadObject:(id)object
{
    DBEntity *entity = [self.scheme entityForClass:[object class]];
    id primaryKey = [object valueForKey:entity.primary.property];
    NSAssert(![DBEntity isEmptyPrimaryKey:primaryKey], @"Can't reload object, since object is not saved (empty primary key)");
    return [self fetchObjectWithId:primaryKey andEntity:entity];
}

- (id)latestPrimaryKeyForObjectClass:(Class)objectClass
{
    __block id latestPrimaryKey = nil;
    DBEntity *entity = [self.scheme entityForClass:[objectClass class]];
    [self executeBlock:^(DBDatabaseProvider *provider) {
        latestPrimaryKey = [provider latestPrimaryKeyForEntity:entity];
    }];
    return latestPrimaryKey;
}

#pragma mark - Deletion

- (void)deleteObject:(id)object completion:(DBDeleteCompletion)completion
{
    DBEntity *entity = [self.scheme entityForClass:[object class]];
    id primaryKey = [object valueForKeyPath:entity.primary.property];
    
    [self executeBlock:^(DBDatabaseProvider *provider) {
        NSError *error = nil;
        [self.objectDeleter deleteObjectWithId:primaryKey withEntity:entity provider:provider error:&error];
        if (completion) {
            completion(error);
        }
    }];
}

@end
