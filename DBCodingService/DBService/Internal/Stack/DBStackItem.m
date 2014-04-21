//
//  DBStackItem.m
//  DBCodingServiceExample
//
//  Created by Aleksey Garbarev on 21.04.14.
//
//

#import "DBStackItem.h"
#import "DBEntity.h"
#import "DBEntityField.h"

@implementation DBStackItem {
    void(^waitingBlock)(id);
}

- (id)primaryKey
{
    return [self.instance valueForKeyPath:self.entity.primary.property];
}

- (void)updatePrimaryKey
{
    id primaryKey = [self primaryKey];
    if (![DBEntity isEmptyPrimaryKey:primaryKey] && waitingBlock) {
        waitingBlock(primaryKey);
        waitingBlock = nil;
    }
}

- (void)waitForPrimaryKeyInBlock:(void(^)(id primaryKey))block
{
    NSParameterAssert(!waitingBlock);
    waitingBlock = block;
    [self updatePrimaryKey];
}

@end
