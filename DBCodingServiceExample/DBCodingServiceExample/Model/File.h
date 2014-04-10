//
//  File.h
//  DBCodingServiceExample
//
//  Created by Aleksey Garbarev on 10.04.14.
//
//

#import <Foundation/Foundation.h>
#import "DBCoder.h"

@interface File : NSObject <DBCoding>

@property (nonatomic) NSUInteger fileId;

@property (nonatomic, strong) NSString *filePath;
@property (nonatomic) NSUInteger fileSize;
@property (nonatomic, strong) NSString *mime;

@end
