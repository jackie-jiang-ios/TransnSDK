//
//  TRReservation.h
//  TransnSDK
//
//  Created by 姜政 on 2018/4/20.
//  Copyright © 2018年 Transn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TRFileObject.h"

//预约单
@interface TRReservation : NSObject
#pragma mark 预估时返回参数
/*!
 *    需要翻译的文档数组
 */
@property(nonatomic,strong)NSArray <TRFileObject *>*translateObjects;

/*!
 *    总字数
 */
@property(nonatomic,copy)NSString *count;
/*!
 *    估时（单位：分钟）
 */
@property(nonatomic,copy)NSString *minutes;
#pragma mark 下单请求参数

/*!
 *   业务方订单id
 */
@property(nonatomic,copy)NSString *sourceId;

/*!
 *   业务方用户id
 */
@property(nonatomic,copy)NSString *userId;

/*!
 *   直连译员id,非必传
 */
@property(nonatomic,copy)NSString *translatorId;

/*!
 *   用户下单时的留言备注
 */
@property(nonatomic,copy)NSString *remark;

/*!
 *   回调方式 1多请求 0单请求,可以不传
 */
@property(nonatomic,assign)NSInteger callbackType;

/*!
 *   回调地址
 */
@property(nonatomic,copy)NSString *callback;

/*!
 *   客户自定义参数（在回调中原样返回)
 */
@property(nonatomic,copy)NSString *bizResult;

#pragma mark 下单返回参数
/*!
 *   下单成功的orderId
 */
@property(nonatomic,copy)NSString *orderId;
@end
