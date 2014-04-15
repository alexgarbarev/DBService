//
//  Message.h
//  DBCodingServiceExample
//
//  Created by Aleksey Garbarev on 10.04.14.
//
//

#import <Foundation/Foundation.h>

@interface Message : NSObject

@property (nonatomic) NSInteger messageId;

@property (nonatomic, strong) NSString *text;
@property (nonatomic, strong) NSArray *attachments;

@end
