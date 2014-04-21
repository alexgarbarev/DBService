//
//  DBStack.m
//  DBCodingServiceExample
//
//  Created by Aleksey Garbarev on 21.04.14.
//
//

#import "DBStack.h"
#import "DBEntity.h"
#import "DBEntityRelation.h"

@implementation DBStack {
    NSMutableDictionary *itemsForRelations;
    NSMutableArray *stack;
}


- (instancetype)init
{
    self = [super init];
    if (self) {
        stack = [NSMutableArray new];
        
        itemsForRelations = [NSMutableDictionary new];
    }
    return self;
}

- (void)useItem:(DBStackItem *)item forRelation:(DBEntityRelation *)relation inBlock:(void(^)())block
{
    NSAssert(itemsForRelations[relation] == nil, @"Item already exists for %@ relations", relation);

    itemsForRelations[[relation description]] = item;
    
    block();
    
    [itemsForRelations removeObjectForKey:[relation description]];
}

- (DBStackItem *)itemForEntity:(DBEntity *)entity withPrimaryKey:(id)primaryKeyValue
{
    __block DBStackItem *foundItem = nil;
    [stack enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(DBStackItem *item, NSUInteger idx, BOOL *stop) {
        if ([item.entity isEqualToEntity:entity] && [item.primaryKey isEqual:primaryKeyValue]) {
            foundItem = item;
            *stop = YES;
        }
    }];
    return foundItem;
}

- (void)useCurrentItemForRelation:(DBEntityRelation *)relation inBlock:(void (^)())block
{
    NSAssert([self currentItem], @"Haven't current item");
    [self useItem:[self currentItem] forRelation:relation inBlock:block];
}

- (DBStackItem *)itemForRelation:(DBEntityRelation *)relation
{
    return itemsForRelations[[relation description]];
}

- (void)push:(DBStackItem *)item
{
    [stack addObject:item];
}

- (DBStackItem *)pop
{
    DBStackItem *item = [stack lastObject];
    [stack removeLastObject];
    return item;
}

- (DBStackItem *)currentItem
{
    return [stack lastObject];
}

@end
