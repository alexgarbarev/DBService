//
//  DBObjectSaver.h
//  DBCodingServiceExample
//
//  Created by Aleksey Garbarev on 18.04.14.
//
//

#import <Foundation/Foundation.h>
@class DBEntity;

@interface DBObjectSaver : NSObject

- (void)save:(id)object withEntity:(DBEntity *)entity completion:(void(^)(BOOL wasInserted, id objectId, NSError * error))completion;

@end
