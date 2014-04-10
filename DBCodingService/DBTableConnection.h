//
//  DBTableConnection.h
//  qliq
//
//  Created by Aleksey Garbarev on 06.12.12.
//
//

#import <Foundation/Foundation.h>

@interface DBTableConnection : NSObject<NSCopying>

@property (nonatomic, strong) NSString *table;
@property (nonatomic, strong) NSString *relationPKColumn;
@property (nonatomic, strong) NSString *encoderColumn;
@property (nonatomic, strong) NSString *encodedObjectColumn;

- (id)initWithTable:(NSString *)table relationPKColumn:(NSString *)relationPKColumn encoderColumn:(NSString *)onColumn encodedObjectColumn:(NSString *) _byColumn;
+ (id)connectionWithTable:(NSString *)table relationPKColumn:(NSString *)relationPKColumn encoderColumn:(NSString *)encoderColumn encodedObjectColumn:(NSString *)encodedColumn;

@end
