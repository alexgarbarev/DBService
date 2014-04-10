//
//  DBCoderData.m
//  DBCodingServiceExample
//
//  Created by Aleksey Garbarev on 10.04.14.
//
//

#import "DBCoderData.h"
#import "DBTableConnection.h"

@interface DBCoderDataValue : NSObject

@property (nonatomic, strong) id value;
@property (nonatomic) Class valueClass;

@end

@implementation DBCoderDataValue
@end

////////////////////////////////////////


@implementation DBCoderData {
    NSMutableDictionary *valuesForColumns;
    NSMutableDictionary *oneToManyValues;
    NSMutableDictionary *manyToManyCoders;
    
    NSSet *ignoredColumns;
}

- (id)init
{
    self = [super init];
    if (self) {
        valuesForColumns = [NSMutableDictionary new];
        oneToManyValues = [NSMutableDictionary new];
        manyToManyCoders = [NSMutableDictionary new];
    }
    return self;
}

- (instancetype)initWithEncodingIgnoredColumns:(NSArray *)encodingIgnoredColumns
{
    self = [self init];
    if (self) {
        ignoredColumns = [NSSet setWithArray:encodingIgnoredColumns];
    }
    return self;
}

- (NSArray *)allColumns
{
    return [valuesForColumns allKeys];
}

- (NSUInteger)columnsCount
{
    return [valuesForColumns count];
}

- (DBCoderDataValue *)dataValueForColumn:(NSString *)column
{
    return valuesForColumns[column];
}

- (Class)valueClassForColumn:(NSString *)column
{
    DBCoderDataValue *value = [self dataValueForColumn:column];
    return value.valueClass ? value.valueClass : [value.value class];
}

- (id)valueForColumn:(NSString *)column
{
    DBCoderDataValue *value = [self dataValueForColumn:column];
    return value.value;
}

- (void)setObject:(id)object withClass:(Class)objectClass forColumn:(NSString *)column
{
    if (object && column && ![ignoredColumns containsObject:column]) {
        DBCoderDataValue *value = [DBCoderDataValue new];
        value.value = object;
        value.valueClass = objectClass;
        valuesForColumns[column] = value;
    }
}

- (void)removeObjectForColumn:(NSString *)column
{
    [valuesForColumns removeObjectForKey:column];
}

- (void)setObjects:(NSArray *)objects withForeignKey:(NSString *)key
{
    if (objects && key) {
        oneToManyValues[key] = objects;
    }
}

- (void)removeObjectsForForeignKey:(NSString *)key
{
    [oneToManyValues removeObjectForKey:key];
}

- (void)setCoders:(NSArray *)coders forConnection:(DBTableConnection *)connection
{
    manyToManyCoders[connection] = coders;
}

- (NSArray *)allManyToManyConnections
{
    return [manyToManyCoders allKeys];
}

- (void)enumerateManyToManyCodersForConnection:(DBTableConnection *)connection usingBlock:(void(^)(DBCoder *connectionCoder))block
{
    NSArray *array = manyToManyCoders[connection];
    for (DBCoder *coder in array) {
        block(coder);
    }
}

- (NSArray *)allOneToManyForeignKeys
{
    return [oneToManyValues allKeys];
}

- (void)enumerateOneToManyObjectsForKey:(NSString *)foreigKey usingBlock:(void(^)(id value))enumerationBlock
{
    NSArray *values = oneToManyValues[foreigKey];
    for (id value in values) {
        enumerationBlock(value);
    }
}

@end
