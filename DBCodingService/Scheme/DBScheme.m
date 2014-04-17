//
//  DBScheme.m
//  DBCodingServiceExample
//
//  Created by Aleksey Garbarev on 16.04.14.
//
//

#import "DBScheme.h"
#import "DBEntity.h"
#import "DBEntityRelation.h"
#import "DBOneToManyRelation.h"
#import "DBOneToOneRelation.h"
#import "DBEntityRelationRepresentation.h"

@implementation DBScheme {
    NSMutableDictionary *entities;
    NSMutableSet *relations;
}

- (id)init
{
    self = [super init];
    if (self) {
        entities = [NSMutableDictionary new];
        relations = [NSMutableSet new];
    }
    return self;
}

- (void)registerEntity:(DBEntity *)entity
{
    NSString *className = NSStringFromClass(entity.objectClass);
    entities[className] = entity;
}

- (void)registerRelation:(DBEntityRelation *)relation
{
    //TODO: Think about data structure to store relations - to have ability to fast iteration over relations for specified entity (instead of iteration over all relations)
    [relations addObject:relation];
}

- (DBEntity *)entityForClass:(Class)objectClass
{
    return entities[NSStringFromClass(objectClass)];
}

- (NSArray *)allEntities
{
    return [entities allValues];
}

- (void)enumerateRelationsFromEntity:(DBEntity *)entity usingBlock:(void(^)(DBEntityRelationRepresentation *, BOOL *stop))block
{
    if (!block) {
        return;
    }
    
    for (DBEntityRelation *relation in relations) {
        BOOL stop = NO;
        
        if ([relation.toEntity isEqualToEntity:entity] || [relation.fromEntity isEqualToEntity:entity]) {
            block([relation representationFromEntity:entity], &stop);
        }

        if (stop) {
            break;
        }
    }
}

- (void)enumerateToOneRelationsFromEntity:(DBEntity *)entity usingBlock:(void(^)(DBEntityRelationRepresentation *, BOOL *stop))block
{
    [self enumerateRelationsFromEntity:entity usingBlock:^(DBEntityRelationRepresentation *represent, BOOL *stop) {
        if (represent.type == DBEntityRelationTypeManyToOne || represent.type == DBEntityRelationTypeOneToOne) {
            block(represent, stop);
        }
    }];    
}

@end
