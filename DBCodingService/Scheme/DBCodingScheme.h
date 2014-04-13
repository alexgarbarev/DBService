//
//  DBCodingScheme.h
//  DBCodingServiceExample
//
//  Created by Aleksey Garbarev on 14.04.14.
//
//

#import <Foundation/Foundation.h>
#import "DBScheme.h"
#import "DBCoding.h"

@interface DBCodingScheme : NSObject <DBScheme>

- (instancetype)initWithDBCodingClass:(Class<DBCoding>)codingClass;

@end
