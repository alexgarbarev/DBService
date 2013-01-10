//
//  DBTableConnection.m
//  qliq
//
//  Created by Aleksey Garbarev on 06.12.12.
//
//

#import "DBTableConnection.h"

@implementation DBTableConnection

@synthesize table, onColumn, byColumn;

+ (id) connectionWithTable:(NSString *) table connectedOn:(NSString *) onColumn by:(NSString *) byColumn{
    return [[DBTableConnection alloc] initWithTable:table connectedOn:onColumn by:byColumn];
}

- (id) initWithTable:(NSString *) _table connectedOn:(NSString *) _onColumn by:(NSString *) _byColumn{
    self = [super init];
    if (self) {
        table = _table;
        onColumn = _onColumn;
        byColumn = _byColumn;
    }
    return self;
}

@end