
#import "NSInvocation_Class.h"
#import <objc/runtime.h>
#import <objc/message.h>

#if __has_feature(objc_arc)
#error NSInvocation_Class is not ARC! Please turn off ARC for this file by adding -fno-objc-arc flag
#endif

@implementation NSInvocation (Class_Reflection)

+ (void)invokeTarget:(id)object withSelector:(SEL)selector ofClass:(Class)objectClass
{
    void(*implementation)(id, SEL) = (void *)[self implementationForSelector:selector onClass:objectClass withTarget:object];
    implementation(object, selector);
}

+ (void)invokeTarget:(id)object withSelector:(SEL)selector ofClass:(Class)objectClass arg:(id)arg
{
    void(*implementation)(id, SEL, id) = (void *)[self implementationForSelector:selector onClass:objectClass withTarget:object];
    implementation(object, selector, arg);
}

+ (id)resultOfInvokingTarget:(id)object withSelector:(SEL)selector ofClass:(Class)objectClass arg:(id)arg
{
    id(*implementation)(id, SEL, id) = (void *)[self implementationForSelector:selector onClass:objectClass withTarget:object];
    return implementation(object, selector, arg);
}

+ (id)resultOfInvokingTarget:(id)object withSelector:(SEL)selector ofClass:(Class)objectClass
{
    id(*implementation)(id, SEL) = (void *)[self implementationForSelector:selector onClass:objectClass withTarget:object];
    return implementation(object, selector);
}

+ (BOOL)boolOfInvokingTarget:(id)object withSelector:(SEL)selector ofClass:(Class)objectClass arg:(id)arg
{
    BOOL(*implementation)(id, SEL, id) = (void *)[self implementationForSelector:selector onClass:objectClass withTarget:object];
    return implementation(object, selector, arg);
}

+ (BOOL)boolOfInvokingTarget:(id)object withSelector:(SEL)selector ofClass:(Class)objectClass arg:(id)arg1 arg:(id)arg2
{
    BOOL(*implementation)(id, SEL, id, id) = (void *)[self implementationForSelector:selector onClass:objectClass withTarget:object];
    return (BOOL)implementation(object, selector, arg1, arg2);
}

+ (IMP)implementationForSelector:(SEL)selector onClass:(Class)clazz withTarget:(id)target
{
    BOOL isClassMethod = class_isMetaClass(object_getClass(target));
    
    if (isClassMethod) {
        return method_getImplementation(class_getClassMethod(clazz, selector));
    } else {
        return method_getImplementation(class_getInstanceMethod(clazz, selector));
    }
}

@end