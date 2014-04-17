//
//  Parent.h
//  DBCodingServiceExample
//
//  Created by Aleksey Garbarev on 18.04.14.
//
//

#import <Foundation/Foundation.h>
#import "Grandparent.h"

@interface Parent : Grandparent

@property (nonatomic, strong) NSNumber *parentId;
@property (nonatomic, strong) NSString *parent;

@end
