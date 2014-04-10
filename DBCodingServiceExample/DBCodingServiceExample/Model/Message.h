//
//  Message.h
//  DBCodingServiceExample
//
//  Created by Aleksey Garbarev on 10.04.14.
//
//

#import <Foundation/Foundation.h>
#import "DBCodingService.h"

@interface Message : NSObject <DBCoding>

@property (nonatomic) NSInteger messageId;

@property (nonatomic, strong) NSString *text;
@property (nonatomic, strong) NSArray *attachments;

@end
