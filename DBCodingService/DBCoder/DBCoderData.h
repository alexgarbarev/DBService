//
//  DBCoderData.h
//  DBCodingServiceExample
//
//  Created by Aleksey Garbarev on 10.04.14.
//
//

#import <Foundation/Foundation.h>

@class FMResultSet;
@class DBTableConnection;
@class DBCoder;

@interface DBCoderData : NSObject

- (instancetype)initWithEncodingIgnoredColumns:(NSArray *)encodingIgnoredColumns;

- (NSArray *)allColumns;
- (NSUInteger)columnsCount;

- (id)valueForColumn:(NSString *)column;
- (Class)valueClassForColumn:(NSString *)column;

- (void)setObject:(id)object withClass:(Class)objectClass forColumn:(NSString *)column;
- (void)removeObjectForColumn:(NSString *)column;

- (void)setObjects:(NSArray *)objects withForeignKey:(NSString *)key;
- (void)removeObjectsForForeignKey:(NSString *)key;

- (void)setCoders:(NSArray *)coders forConnection:(DBTableConnection *)connection;

- (void)enumerateManyToManyCoders:(void(^)(DBCoder *coder, DBTableConnection *connection))enumerationBlock;
- (void)enumerateOnToManyObjects:(void(^)(id value, NSString *foreignKey))enumerationBlock;

@end
