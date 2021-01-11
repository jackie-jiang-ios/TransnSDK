//
//  TRBaseModel.m
//  TransnSDK
//
//  Created by VanRo on 16/6/1.
//  Copyright © 2016年 Transn. All rights reserved.
//

#import "TRBaseModel.h"
@implementation TRBaseModel

@synthesize result, code;
@synthesize isStatusOK = _isStatusOK;

- (BOOL)isStatusOK
{
    _isStatusOK = ([[NSString stringWithFormat:@"%@", result] isEqualToString:@"1"]);
    return _isStatusOK;
}

- (NSString *)msg
{
    if ([_msg length] == 0) {
        _msg = NSLocalizedString(@"未知错误", @"未知错误");
    }
    
    return _msg;
}

- (id)initWithDictionary:(NSDictionary *)dict
{
    if (self = [super init]) {
        if (dict) {
            [self setUpBaseInfoWithDic:dict];
        }
    }
    
    return self;
}

- (void)setUpBaseInfoWithDic:(NSDictionary *)dict
{
    @try
    {
        if ([dict isKindOfClass:[NSDictionary class]] == NO) {
            return;
        }
        
        result = [NSString stringWithFormat:@"%@", [dict objectForKey:@"result"]];
        if ([dict objectForKey:@"msg"]) {
            _msg = [dict objectForKey:@"msg"];//老SDK
        }else{
            _msg = [dict objectForKey:@"errorMsg"];//新的接口，董浩那边的
        }

        _data = [dict objectForKey:@"data"];
        code = -1;
        
        if ([dict objectForKey:@"code"]) {
            code = [[NSString stringWithFormat:@"%@", [dict objectForKey:@"code"]] intValue];
        }else{
            code = [[NSString stringWithFormat:@"%@", [dict objectForKey:@"errorCode"]] intValue];
        }
        
        if ((_msg == nil) && _data && [_data isKindOfClass:[NSDictionary class]]) {
            if ([_data objectForKey:@"msg"]) {
                     _msg = [_data objectForKey:@"msg"];
            }else{
                     _msg = [_data objectForKey:@"errorMsg"];
            }
      
        }
    }
    @catch(NSException *exception) {
        //        TRLog(@"exception");
    }
}

@end
