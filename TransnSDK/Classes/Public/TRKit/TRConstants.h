/*!
 *   TRConstants.h
 *   TransnSDK
 *
 *   Created by 姜政 on 2017/8/16.
 *   Copyright © 2018年 Transn. All rights reserved.
 *
 */

#ifndef TRConstants_h
#define TRConstants_h
#import "TRNotification.h"
#import "TRFileLog.h"

#define TRLog(FORMAT, ...) [[TRFileLog sharedManager] log:[NSString stringWithFormat:FORMAT, ##__VA_ARGS__]]

#pragma mark SDK 1.5.1 2017-08-16
/**
 *   调试模式
 *
 *   - TransnEnvironmentProduct: 生产环境
 *   - TransnEnvironmentDevelopment: 开发环境
 *   - TransnEnvironmentTest: 测试环境
 */
typedef NS_ENUM (NSInteger, TransnEnvironment) {
    TransnEnvironmentProduct = 0,
    TransnEnvironmentDevelopment = 1,
    TransnEnvironmentTest = 2,
};




///TransnSDK 回调Block
typedef void (^ TIMCompletionBlock) (id result, NSError *error);

#define TRAPIDeprecated(instead)            NS_DEPRECATED(8_0, 8_0, 8_0, 8_0, instead)
#ifndef TRDicWithOAndK
#define TRDicWithOAndK(firstObject, ...)    [NSDictionary dictionaryWithObjectsAndKeys: firstObject, ##__VA_ARGS__, nil]
#endif

#endif /* TRConstants_h */
