//
//  DBStackItem.h
//  DBCodingServiceExample
//
//  Created by Aleksey Garbarev on 21.04.14.
//
//

#import <Foundation/Foundation.h>

@class DBEntity;

@interface DBStackItem : NSObject

@property (nonatomic, strong) id instance;
@property (nonatomic, strong) DBEntity *entity;

@property (nonatomic, readonly) id primaryKey;

- (void)waitForPrimaryKeyInBlock:(void(^)(id primaryKey))block;

@end
