//
//  DBObjectSaver.h
//  DBCodingServiceExample
//
//  Created by Aleksey Garbarev on 18.04.14.
//
//

#import <Foundation/Foundation.h>

@class DBEntity;
@class DBScheme;
@class DBDatabaseProvider;

@interface DBObjectSaver : NSObject

- (instancetype)initWithScheme:(DBScheme *)scheme;

- (void)save:(id)object withEntity:(DBEntity *)entity provider:(DBDatabaseProvider *)provider completion:(void(^)(BOOL wasInserted, id objectId, NSError * error))completion;

@end
