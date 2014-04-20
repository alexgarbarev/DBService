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

@implementation DBStackItem

- (id)primaryKey
{
    return [self.instance valueForKeyPath:self.entity.primary.property];
}

- (void)waitForPrimaryKeyInBlock:(void(^)(id primaryKey))block
{

}

@end
