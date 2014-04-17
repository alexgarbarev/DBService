//
//  Child.h
//  DBCodingServiceExample
//
//  Created by Aleksey Garbarev on 18.04.14.
//
//

#import <Foundation/Foundation.h>
#import "Parent.h"
@interface Child : Parent

@property (nonatomic, strong) NSNumber *childId;
@property (nonatomic, strong) NSString *child;

@end
