//
//  DBObjectDecoder.m
//  DBCodingServiceExample
//
//  Created by Aleksey Garbarev on 16.04.14.
//
//

#import "DBObjectDecoder.h"
#import "FMResultSet.h"
#import "DBEntity.h"
#import "DBScheme.h"
#import "DBEntityField.h"
#import "DBEntityRelationRepresentation.h"
#import "DBParentRelation.h"

@interface DBObjectDecoder ()
@property (nonatomic, strong) DBScheme *scheme;
@end

@implementation DBObjectDecoder

- (instancetype)initWithScheme:(DBScheme *)scheme
{
    self = [super init];
    if (self) {
        self.scheme = scheme;
    }
    return self;
}

- (id)objectWithId:(id)primaryKeyValue entity:(DBEntity *)entity fromFetcher:(DBObjectDecoderFetcher *)fetcher
{
    return [self objectWithId:primaryKeyValue entity:entity fromFetcher:fetcher exceptRelations:nil];
}

- (id)objectWithId:(id)primaryKeyValue entity:(DBEntity *)entity fromFetcher:(DBObjectDecoderFetcher *)fetcher exceptRelations:(NSSet *)relationsToExclude
{
    id object = nil;
    if (primaryKeyValue && ![primaryKeyValue isKindOfClass:[NSNull class]]) {
        FMResultSet *objectResultSet = [fetcher resultSetForPrimaryKeyValue:primaryKeyValue andEntity:entity];
        if ([objectResultSet next]) {
            object = [self decodeObjectFromResultSet:objectResultSet withEntity:entity fetcher:fetcher options:0 exceptRelations:relationsToExclude];
        }
        [objectResultSet close];
    }
    return object;
}

- (id)decodeObjectFromResultSet:(FMResultSet *)resultSet withEntity:(DBEntity *)entity fetcher:(DBObjectDecoderFetcher *)fetcher options:(DBObjectDecoderOptions)options
{
    return [self decodeObjectFromResultSet:resultSet withEntity:entity fetcher:fetcher options:options exceptRelations:nil];
}

- (id)decodeObjectFromResultSet:(FMResultSet *)resultSet withEntity:(DBEntity *)entity fetcher:(DBObjectDecoderFetcher *)fetcher options:(DBObjectDecoderOptions)options exceptRelations:(NSSet *)relationsToExclude
{
    NSAssert(!entity.abstract, @"Can't decode object of abstract entity");
    
    id object = [[[entity objectClass] alloc] init];
    
    [self decodedObject:object withResultSet:resultSet entity:entity fetcher:fetcher exceptRelations:relationsToExclude];
    
    /* Fill object with parent tables */
    if (entity.parentRelation) {
        id parentPrimaryKey = [resultSet objectForColumnName:entity.parentRelation.childColumnField.column];
        [self decodeParentWithId:parentPrimaryKey inObject:object withParentRelation:entity.parentRelation fetcher:fetcher];
    }
    
    return object;
}

- (void)decodeParentWithId:(id)parentPrimaryKey inObject:(id)object withParentRelation:(DBParentRelation *)parentRelation fetcher:(DBObjectDecoderFetcher *)fetcher
{
    while (parentRelation) {
        FMResultSet *parentResultSet = [fetcher resultSetForPrimaryKeyValue:parentPrimaryKey andEntity:parentRelation.parentEntity];
        [self decodedObject:object withResultSet:parentResultSet entity:parentRelation.parentEntity fetcher:fetcher exceptRelations:nil];
        parentRelation = parentRelation.parentEntity.parentRelation;
        if (parentRelation) {
            parentPrimaryKey = [parentResultSet objectForColumnName:parentRelation.childColumnField.column];
        }
        [parentResultSet close];
    }
}

- (void)decodedObject:(id)object withResultSet:(FMResultSet *)resultSet entity:(DBEntity *)entity fetcher:(DBObjectDecoderFetcher *)fetcher exceptRelations:(NSSet *)relationsToExclude
{
    [self writeObject:object fromResultSet:resultSet usingEntity:entity];
    [self resolveToOneRelationsInObject:object usingEntity:entity andResultSet:resultSet fetcher:fetcher exceptRelations:relationsToExclude];
    [self resolveToManyRelationsInObject:object usingEntity:entity andResultSet:resultSet fetcher:fetcher];
}

- (void)writeObject:(id)object fromResultSet:(FMResultSet *)resultSet usingEntity:(DBEntity *)entity
{
    NSMutableSet *fieldsToWrite = [[[entity fields] set] mutableCopy];
    [fieldsToWrite minusSet:[self fieldsWithRelationsFromEntity:entity]];
    
    for (DBEntityField *field in fieldsToWrite) {
        if (field.property && field.column) {
            id value = [resultSet objectForColumnName:field.column];
            if (![value isKindOfClass:[NSNull class]]) {
                [object setValue:value forKey:field.property];
            }
        }
    }
}

- (void)resolveToOneRelationsInObject:(id)object usingEntity:(DBEntity *)entity andResultSet:(FMResultSet *)resultSet fetcher:(DBObjectDecoderFetcher *)fetcher exceptRelations:(NSSet *)relationsToExclude
{
    NSMutableSet *relationsToResolve = [NSMutableSet new];
    NSMutableSet *circularRelations = [NSMutableSet new];
    [self.scheme enumerateToOneRelationsFromEntity:entity usingBlock:^(DBEntityRelationRepresentation *relation, BOOL *stop) {
        if (relation.fromField.property && relation.fromField.column && ![relationsToExclude containsObject:relation.relation]) {
            if (relation.toField && relation.type == DBEntityRelationTypeOneToOne) {
                [circularRelations addObject:relation.relation];
            }
            [relationsToResolve addObject:relation];
        }
    }];
    
    for (DBEntityRelationRepresentation *relation in relationsToResolve) {
        id foreignObjectId = [resultSet objectForColumnName:relation.fromField.column];
        id foreignObject = [self objectWithId:foreignObjectId entity:relation.toEntity fromFetcher:fetcher exceptRelations:circularRelations];
        [object setValue:foreignObject forKey:relation.fromField.property];
        if ([circularRelations containsObject:relation.relation]) {
            [foreignObject setValue:object forKey:relation.toField.property];
        }
    }
}

- (void)resolveToManyRelationsInObject:(id)object usingEntity:(DBEntity *)entity andResultSet:(FMResultSet *)resultSet fetcher:(DBObjectDecoderFetcher *)fetcher
{
    
}

- (NSSet *)fieldsWithRelationsFromEntity:(DBEntity *)entity
{
    NSMutableSet *fieldsWithRelations = [[NSMutableSet alloc] initWithCapacity:entity.fields.count];
    
    [self.scheme enumerateRelationsFromEntity:entity usingBlock:^(DBEntityRelationRepresentation *relation, BOOL *stop) {
        [fieldsWithRelations addObject:relation.fromField];
    }];
    
    return fieldsWithRelations;
}

- (NSSet *)fieldsWithToOneRelationsFromEntity:(DBEntity *)entity
{
    NSMutableSet *fieldsWithRelations = [[NSMutableSet alloc] initWithCapacity:entity.fields.count];
    
    [self.scheme enumerateToOneRelationsFromEntity:entity usingBlock:^(DBEntityRelationRepresentation *relation, BOOL *stop) {
        [fieldsWithRelations addObject:relation.fromField];
    }];
    
    return fieldsWithRelations;
}

@end
