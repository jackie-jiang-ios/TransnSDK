/*!
 *   TRBaseModel.h
 *   TransnSDK
 *
 *   Created by 姜政 on 16/6/1.
 *   Copyright © 2018年 Transn. All rights reserved.
 *
 */
#import <Foundation/Foundation.h>

@interface TRBaseModel : NSObject

/*!
 *   @abstract  请求的状态
 *   @result 等于1就是成功，其它失败
 */
@property (nonatomic, copy) NSString *result;

/*!
 *   @abstract  错误信息
 *   @result 提示的错误字符串
 */
@property (nonatomic, copy) NSString *msg;

/*!
 *   @abstract  错误码
 *   @result 后台返回的错误码
 */
@property (nonatomic, assign) int code;

/*!
 *   @abstract 请求结果
 *   @result 根据reslut获得的，yes就是成功，flase就是失败
 */
@property (nonatomic, assign) BOOL isStatusOK;

/*!
 *   @abstract 返回的结果
 *   @result  一般是dict
 */
@property (nonatomic, strong) id data;

/*!
 *   @method  通过dic初始化一个TRBaseModel
 *   @param dic 译员ID
 *   @return 返回一个TRBaseModel对象
 */
- (id)initWithDictionary:(NSDictionary *)dic;

@end
