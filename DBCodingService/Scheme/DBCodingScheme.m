//
//  DBCodingScheme.m
//  DBCodingServiceExample
//
//  Created by Aleksey Garbarev on 14.04.14.
//
//

#import "DBCodingScheme.h"
#import "NSObject+DBScheme.h"
#import "DBCoder.h"
#import "NSInvocation_Class.h"
#import <objc/runtime.h>

@implementation DBCodingScheme {
    Class codingClass;
}

@synthesize parentScheme;

- (instancetype)initWithDBCodingClass:(Class<DBCoding>)_codingClass
{
    self = [super init];
    if (self) {
        codingClass = _codingClass;
        
        Class superClass = class_getSuperclass(codingClass);
        if ([superClass conformsToProtocol:@protocol(DBCoding)]) {
            self.parentScheme = [superClass scheme];
            if (![self parentSchemeColumn]) {
                self.parentScheme = nil;
            }
        }
        
    }
    return self;
}

#pragma mark - DBScheme protocol

- (NSString *)table
{
    return [codingClass dbTable];
}

- (NSString *)primaryKeyColumn
{
    return [codingClass dbPKColumn];
}

- (id)primaryKeyValueFromObject:(id)object
{
    NSString *primaryKeyPropertyKey = [NSInvocation resultOfInvokingTarget:object withSelector:@selector(dbPKProperty) ofClass:codingClass];
    id value = [(NSObject *)object valueForKey:primaryKeyPropertyKey];
    
    if ([value isKindOfClass:[NSNumber class]] && [value integerValue] == 0) {
        value = nil;
    }
    if ([value isKindOfClass:[NSString class]] && [value length] == 0) {
        value = nil;
    }
    return value;
}

- (void)setPrimaryKeyValue:(id)value forObject:(id)object
{
    NSString *primaryKeyPropertyKey = [NSInvocation resultOfInvokingTarget:object withSelector:@selector(dbPKProperty) ofClass:codingClass];
    [(NSObject *)object setValue:value forKey:primaryKeyPropertyKey];
}

- (void)encodeObject:(id)object withCoder:(DBCoder *)encoder
{
    if (self.parentScheme) {
        [encoder encodeObject:object withScheme:self.parentScheme forColumn:[self parentSchemeColumn]];
    }
    [NSInvocation invokeTarget:object withSelector:@selector(encodeWithDBCoder:) ofClass:codingClass arg:encoder];
    
    [encoder encodeObject:[self primaryKeyValueFromObject:object] forColumn:[self primaryKeyColumn]];
}

- (id)decodeObject:(id)object fromCoder:(DBCoder *)decoder;
{
    if (!object) {
        object = [codingClass alloc];
    }
    if (self.parentScheme) {
        object = [self.parentScheme decodeObject:object fromCoder:decoder];
    }
    object = [NSInvocation resultOfInvokingTarget:object withSelector:@selector(initWithDBCoder:) ofClass:codingClass arg:decoder];
    
    if (object) {
        [self setPrimaryKeyValue:[decoder decodeObjectForColumn:[self primaryKeyColumn]] forObject:object];
    }
    
    return object;
}

- (NSString *)parentSchemeColumn
{
    NSString *parentColumn = nil;
    Method method = class_getClassMethod(codingClass, @selector(dbParentColumn));
    if (method) {
        IMP dbParentColumnImp = method_getImplementation(method);
        parentColumn = dbParentColumnImp(codingClass, @selector(dbParentColumn));
    }
    return parentColumn;
}

#pragma mark - Foreign Keys

- (NSString *)foreignKeyColumnForRelationWithScheme:(id<DBScheme>)scheme
{
    if ([self.parentScheme isEqual:scheme]) {
        return [self parentSchemeColumn];
    }
    return nil;
}

- (id<DBScheme>)schemeForForeignKeyColumn:(NSString *)column
{
    if ([column isEqualToString:[self parentSchemeColumn]]) {
        return self.parentScheme;
    }
    return nil;
}

#pragma mark - Deletion rules

- (DBSchemeDeleteRule)deleteRuleForOneToOneRelatedObjectWithScheme:(id<DBScheme>)scheme forColumn:(NSString *)column
{
    DBSchemeDeleteRule rule = DBSchemeDeleteRuleCascade;
    
    SEL selector = @selector(dbShouldDeleteOneToOneRelatedObjectWithScheme:forColumn:);
    if ([codingClass respondsToSelector:selector] && [NSInvocation boolOfInvokingTarget:codingClass withSelector:selector ofClass:codingClass arg:scheme arg:column]) {
        rule = DBSchemeDeleteRuleCascade;
    }
    return rule;
}

- (DBSchemeDeleteRule)deleteRuleForOneToManyRelatedObjectWithScheme:(id<DBScheme>)scheme connectedOnForeignColumn:(NSString *)foreignColumn
{
    DBSchemeDeleteRule rule = DBSchemeDeleteRuleCascade;
    
    SEL selector = @selector(dbShouldDeleteOneToManyRelatedObjectWithScheme:connectedOnForeignColumn:);
    if ([codingClass respondsToSelector:selector] && [NSInvocation boolOfInvokingTarget:codingClass withSelector:selector ofClass:codingClass arg:scheme arg:foreignColumn]) {
        rule = DBSchemeDeleteRuleCascade;
    }
    return rule;
}

- (DBSchemeDeleteRule)deleteRuleForManyToManyRelationWithConnection:(DBTableConnection *)connection
{
    DBSchemeDeleteRule rule = DBSchemeDeleteRuleCascade;
    
    SEL selector = @selector(dbShouldDeleteManyToManyRelationWithConnection:);
    if ([codingClass respondsToSelector:selector] && [NSInvocation boolOfInvokingTarget:codingClass withSelector:selector ofClass:codingClass arg:connection]) {
        rule = DBSchemeDeleteRuleCascade;
    }
    return rule;
}

- (DBSchemeDeleteRule)deleteRuleForManyToManyRelatedObjectWithScheme:(id<DBScheme>)scheme andConnection:(DBTableConnection *)connection
{
    DBSchemeDeleteRule rule = DBSchemeDeleteRuleNoAction;
    
    SEL selector = @selector(dbShouldDeleteManyToManyRelatedObjectWithScheme:withConnection:);
    if ([codingClass respondsToSelector:selector] && [NSInvocation boolOfInvokingTarget:codingClass withSelector:selector ofClass:codingClass arg:scheme arg:connection]) {
        rule = DBSchemeDeleteRuleCascade;
    }
    return rule;
}

- (NSString *)description
{
    return [[super description] stringByAppendingFormat:@"Coding-class=%@",codingClass];
}

@end
