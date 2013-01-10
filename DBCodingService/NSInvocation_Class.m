
#import "NSInvocation_Class.h"
#import <objc/runtime.h>

#if __has_feature(objc_arc)
#error NSInvocation_Class is not ARC! Please turn off ARC for this file by adding -fno-objc-arc flag
#endif

@implementation NSInvocation (Class_Reflection)

+ (void) invokeTarget:(id) object withSelector:(SEL) selector ofClass:(Class) objectClass{
    [self resultOfInvokingTarget:object withSelector:selector ofClass:objectClass];
}

+ (void) invokeTarget:(id) object withSelector:(SEL) selector ofClass:(Class) objectClass arg:(id)arg{
    [self resultOfInvokingTarget:object withSelector:selector ofClass:objectClass arg:arg];
}

+ (id)  resultOfInvokingTarget:(id) object withSelector:(SEL) selector ofClass:(Class) objectClass arg:(id)arg{
    
    IMP implementation = class_getMethodImplementation(objectClass,selector);
    
    return implementation(object, selector, arg);
}

+ (id)  resultOfInvokingTarget:(id) object withSelector:(SEL) selector ofClass:(Class) objectClass{

    IMP implementation = class_getMethodImplementation(objectClass,selector);
    
    return implementation(object, selector);
}

+ (BOOL) boolOfInvokingTarget:(id) object withSelector:(SEL) selector ofClass:(Class) objectClass arg:(id)arg{
    
    IMP implementation = class_getMethodImplementation(objectClass,selector);

    return (BOOL)implementation(object, selector, arg);
}


@end