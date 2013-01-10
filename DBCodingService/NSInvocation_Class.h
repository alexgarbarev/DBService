//
//  NSInvocation_Class.h
//  qliq
//
//  Created by Aleksey Garbarev on 12/10/12.
//
//

#import <Foundation/Foundation.h>

@interface NSInvocation (Class_Reflection)

+ (void) invokeTarget:(id) object withSelector:(SEL) selector ofClass:(Class) objectClass;
+ (void) invokeTarget:(id) object withSelector:(SEL) selector ofClass:(Class) objectClass arg:(id)arg;

+ (id) resultOfInvokingTarget:(id) object withSelector:(SEL) selector ofClass:(Class) objectClass;
+ (id) resultOfInvokingTarget:(id) object withSelector:(SEL) selector ofClass:(Class) objectClass arg:(id)arg;

+ (BOOL) boolOfInvokingTarget:(id) object withSelector:(SEL) selector ofClass:(Class) objectClass arg:(id)arg;

@end

