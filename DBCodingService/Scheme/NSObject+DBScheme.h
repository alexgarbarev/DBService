//
//  NSObject+DBScheme.h
//  DBCodingServiceExample
//
//  Created by Aleksey Garbarev on 14.04.14.
//
//

#import <Foundation/Foundation.h>
@protocol DBScheme;

@interface NSObject (DBScheme)

+ (id<DBScheme>)scheme;

@end
