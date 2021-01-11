//
//  NSObject+TRKeyValue.m
//  TransnSDK
//
//  Created by 姜政 on 2018/4/17.
//  Copyright © 2018年 Transn. All rights reserved.
//

#import "NSObject+TRKeyValue.h"

@implementation NSObject (TRKeyValue)
#pragma mark - 转换为JSON
- (NSData *)tr_JSONData
{
    if ([self isKindOfClass:[NSString class]]) {
        return [((NSString *)self) dataUsingEncoding:NSUTF8StringEncoding];
    } else if ([self isKindOfClass:[NSData class]]) {
        return (NSData *)self;
    }
    
    return [NSJSONSerialization dataWithJSONObject:[self tr_JSONObject] options:kNilOptions error:nil];
}

- (id)tr_JSONObject
{
    if ([self isKindOfClass:[NSString class]]) {
        return [NSJSONSerialization JSONObjectWithData:[((NSString *)self) dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:nil];
    } else if ([self isKindOfClass:[NSData class]]) {
        return [NSJSONSerialization JSONObjectWithData:(NSData *)self options:kNilOptions error:nil];
    }
    //dict
    return self;
}

- (NSString *)tr_JSONString
{
    if ([self isKindOfClass:[NSString class]]) {
        return (NSString *)self;
    } else if ([self isKindOfClass:[NSData class]]) {
        return [[NSString alloc] initWithData:(NSData *)self encoding:NSUTF8StringEncoding];
    }
    
    return [[NSString alloc] initWithData:[self tr_JSONData] encoding:NSUTF8StringEncoding];
}
@end
