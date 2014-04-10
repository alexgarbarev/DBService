//
//  DBCoding.h
//  DBCodingServiceExample
//
//  Created by Aleksey Garbarev on 10.04.14.
//
//

#import <Foundation/Foundation.h>

@class DBCoder;
@class DBTableConnection;

@protocol DBCoding <NSObject>

/* Do not call this method directly to init object with coder.
 * Use objectOfClass:fromDecoder: in QliqDBService instead */
- (id)initWithDBCoder:(DBCoder *)decoder;

- (void)encodeWithDBCoder:(DBCoder *)coder;

- (NSString *)dbPKProperty; //KVC key for property which store primary key

+ (NSString *)dbTable;      // table name for object
+ (NSString *)dbPKColumn;   // primary key column name

@optional

/** Default: YES */
+ (BOOL)dbShouldDeleteOneToOneRelatedObjectWithClass:(Class)objectClass forColumn:(NSString *)column;

/** Default: YES */
+ (BOOL)dbShouldDeleteOneToManyRelatedObjectWithClass:(Class)objectClass connectedOnForeignColumn:(NSString *)foreignColumn;

/** Default: YES */
+ (BOOL)dbShouldDeleteManyToManyRelationWithConnection:(DBTableConnection *)connection;

/** Default: NO */
+ (BOOL)dbShouldDeleteManyToManyRelatedObjectWithClass:(Class)objectClass withConnection:(DBTableConnection *)connection;

@end

