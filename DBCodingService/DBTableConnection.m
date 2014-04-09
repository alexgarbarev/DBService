//
//  DBTableConnection.m
//  qliq
//
//  Created by Aleksey Garbarev on 06.12.12.
//
//

#import "DBTableConnection.h"

@implementation DBTableConnection {
    NSUInteger hash;
}

@synthesize table, encoderColumn, encodedObjectColumn;

+ (id) connectionWithTable:(NSString *) table encoderColumn:(NSString *) onColumn encodedObjectColumn:(NSString *) byColumn{
    return [[DBTableConnection alloc] initWithTable:table encoderColumn:onColumn encodedObjectColumn:byColumn];
}

- (id) initWithTable:(NSString *) _table encoderColumn:(NSString *) _onColumn encodedObjectColumn:(NSString *) _byColumn{
    self = [super init];
    if (self) {
        table = _table;
        encoderColumn = _onColumn;
        encodedObjectColumn = _byColumn;
        [self calculateHash];
    }
    return self;
}

- (void)calculateHash
{
    hash = [table hash] ^ [encoderColumn hash] ^ [encodedObjectColumn hash];
}

- (NSUInteger)hash
{
    return hash;
}

- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[DBTableConnection class]]) {
        return [self hash] == [object hash];
    } else {
        return NO;
    }
}

- (id)copyWithZone:(NSZone *)zone
{
    return [[DBTableConnection alloc] initWithTable:self.table encoderColumn:self.encoderColumn encodedObjectColumn:self.encodedObjectColumn];
}

@end