//
//  TRError.m
//  TransnSDK
//
//  Created by 姜政 on 2018/4/18.
//  Copyright © 2018年 Transn. All rights reserved.
//

#import "TRError.h"

@implementation TRError

+(NSError*)errorWithDomain:(NSString *)domain code:(NSInteger)code description:(NSString *)description{
    NSDictionary    *userInfo = nil;
    if (description) {
        userInfo =  [NSDictionary dictionaryWithObject:description forKey:NSLocalizedDescriptionKey];
    }else{
         userInfo =  [NSDictionary dictionaryWithObject:@"请查看errorCode" forKey:NSLocalizedDescriptionKey];
    }
    if (domain) {
       return [NSError errorWithDomain:domain code:code userInfo:userInfo];
    }else{
       return [NSError errorWithDomain:@"" code:code userInfo:userInfo];
    }
}
+(void)errorWithCode:(NSInteger)code description:(NSString *)description completion:(void (^)(id result, NSError *error))completion{
    if (completion) {
        NSError *error = [TRError errorWithDomain:nil code:code description:description];
        dispatch_async(dispatch_get_main_queue(), ^{
             completion(nil,error);
        });
    }
}

+(void)paramError:(NSString *)paramName completion:(void (^)(id result, NSError *error))completion{
    if (completion) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(nil,[TRError errorWithDomain:nil code:9990 description:[NSString stringWithFormat:@"%@参数错误",paramName]]);
        });
    }
}

+(void)paramError:(void (^)(id result, NSError *error))completion{
    if (completion) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(nil,[TRError errorWithDomain:nil code:9990 description:@"参数错误"]);
        });
    }
}


+(void)unLoginError:(void (^)(id result, NSError *error))completion{
    if (completion) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(nil,[TRError errorWithDomain:nil code:9991 description:@"用户未登录"]);
        });
    }
}
@end
