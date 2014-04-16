//
//  Icon.h
//  DBCodingServiceExample
//
//  Created by Aleksey Garbarev on 17.04.14.
//
//

#import <Foundation/Foundation.h>

@class File;

@interface Icon : NSObject

@property (nonatomic) NSUInteger iconId;
@property (nonatomic, strong) NSString *path;
@property (nonatomic, strong) File *file;

@end
