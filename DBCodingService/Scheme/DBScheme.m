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

- (void)enumerateToOneRelationsFromEntity:(DBEntity *)entity usingBlock:(void(^)(DBEntityField *fromField, DBEntity *toEntity, DBEntityField *toField, BOOL *stop))block
{
    if (!block) {
        return;
    }
    
    for (DBEntityRelation *relation in relations) {
        BOOL stop = NO;
        if ([relation.toEntity isEqualToEntity:entity] && ([relation isKindOfClass:[DBOneToManyRelation class]] || [relation isKindOfClass:[DBOneToOneRelation class]])) {
            block(relation.toEntityField, relation.fromEntity, relation.fromEntityField, &stop);
        } else if ([relation.fromEntity isEqualToEntity:entity] && [relation isKindOfClass:[DBOneToOneRelation class]]) {
            block(relation.fromEntityField, relation.toEntity, relation.toEntityField, &stop);
        }
        if (stop) {
            break;
        }
    }
}

@end
