//
//  DBScheme.m
//  DBCodingServiceExample
//
//  Created by Aleksey Garbarev on 16.04.14.
//
//

#import "DBScheme.h"
#import "DBEntity.h"

@implementation DBScheme {
    NSMutableDictionary *entities;
}

- (id)init
{
    self = [super init];
    if (self) {
        entities = [NSMutableDictionary new];
    }
    return self;
}

- (void)registerEntity:(DBEntity *)entity
{
    NSString *className = NSStringFromClass(entity.objectClass);
    entities[className] = entity;
}

- (DBEntity *)entityForClass:(Class)objectClass
{
    return entities[NSStringFromClass(objectClass)];
}

- (NSArray *)allEntities
{
    return [entities allValues];
}

@end
