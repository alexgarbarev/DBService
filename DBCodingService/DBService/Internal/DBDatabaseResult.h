//
//  DBDatabaseResult.h
//  DBCodingServiceExample
//
//  Created by Aleksey Garbarev on 19.04.14.
//
//

#import <Foundation/Foundation.h>

@protocol DBDatabaseResult <NSObject>

- (id)objectForColumnName:(NSString*)columnName;

- (BOOL)next;

- (void)close;

@end
