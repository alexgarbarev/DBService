//
//  DBConnectionScheme.h
//  DBCodingServiceExample
//
//  Created by Aleksey Garbarev on 14.04.14.
//
//

#import <Foundation/Foundation.h>
#import "DBScheme.h"

@class DBTableConnection;

@interface DBTableConnectionScheme : NSObject<DBScheme>

- (instancetype)initWithTableConnection:(DBTableConnection *)connectionScheme;

@end
