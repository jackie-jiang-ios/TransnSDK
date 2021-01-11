//
//  TRError.h
//  TransnSDK
//
//  Created by 姜政 on 2018/4/18.
//  Copyright © 2018年 Transn. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TRError : NSError
/*errorCode
 9990 = "参数不合法"
 9991 = "用户未登录"
 9997 = "图片最少1张图片"
 9997 = "图片最少1张图片"
 9998 = "图片最多5张图片"
 9999 = "txt文件不存在"
 10000 = "生成txt文件失败"
 10001 = "上传文件失败"
 10002 = "获取文件FileId失败"
 10003 = "下单失败"
 10004 = "预估价格失败"
 10005 = "留言失败"

 60002 = @"重复登录"
 70000 = @"网络错误"
 */

+(NSError *)errorWithDomain:(NSString *)domain code:(NSInteger)code description:(NSString *)description;

+(void)errorWithCode:(NSInteger)code description:(NSString *)description completion:(void (^)(id result, NSError *error))completion;

+(void)paramError:(void (^)(id result, NSError *error))completion;

+(void)paramError:(NSString *)paramName completion:(void (^)(id result, NSError *error))completion;

+(void)unLoginError:(void (^)(id result, NSError *error))completion;
@end
