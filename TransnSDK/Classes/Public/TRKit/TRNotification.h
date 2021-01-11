/*!
 *   TRNotification.h
 *   TransnSDK
 *
 *   Created by 姜政 on 2018/3/3
 *   Copyright © 2018年 Transn. All rights reserved.
 */

#import <Foundation/Foundation.h>
//比较低频的场景
/// IM状态变更
static NSString *const  IM_Connect_State_Change = @"IM_Connect_State_Change";
/// 将要连接
static NSString *const  IM_Connect_State_WillConnect = @"IM_Connect_State_WillConnect";

///已经连接上
static NSString *const  IM_Connect_State_DidConnect = @"IM_Connect_State_DidConnect";

///失去连接
static NSString *const  IM_Connect_State_DidDisconnect = @"IM_Connect_State_DidDisconnect";

///IM授权成功
static NSString *const  IM_Connect_State_DidAuthenticate = @"IM_Connect_State_DidAuthenticate";

///IM授权失败
static NSString *const  IM_Connect_State_DidNotAuthenticate = @"IM_Connect_State_DidNotAuthenticate";

///心跳包超时了
static NSString *const  IM_Connect_State_AutoPingDidTimeout = @"IM_Connect_State_AutoPingDidTimeout";

///译员正在翻译中
static NSString *const  IM_Chat_State_Composing = @"IM_Chat_State_Composing";

///译员暂停翻译
static NSString *const  IM_Chat_State_Paused = @"IM_Chat_State_Paused";

///小尾巴业务，译员回呼通知
static NSString *const  IM_Chat_Receive_Call = @"IM_Chat_Receive_Call";

///小尾巴业务，收藏的译员上线了
static NSString *const  IM_Chat_CollectTransOnLine = @"IM_Chat_CollectTransOnLine";

//一些TIPS消息
static NSString *const  IM_Extend_TipsMessages = @"IM_Extend_TipsMessages";//具体扩展，看下面的定义

#pragma mark 小尾巴 //防止和其它app的通知冲突，这几个的通知名称有一个默认的拼接 ,看这个方法-(NSString *)notificationNameForTypeString:(NSString *)typeString;
static NSString *const  ReCallUser = @"ReCallUser:";   //ReCallUser    // body:ReCallUser:1_2 //通知用户端APP该用户之前呼叫的这个1-2语种方向（即中-英方向）的译员上线了
static NSString *const  CollectTransOnLine = @"CollectTransOnLine:";//CollectTransOnLine 收藏的译员上线了
#pragma mark transnBox 预约单 2018-03-03
static NSString *const  HwStatusMsg = @"HwStatusMsg:";//HwStatusMsg 硬件状态刷新
static NSString *const  BookOrderReceived = @"BookOrderReceived:";        //BookOrderReceived译员接单
static NSString *const  BookOrderStartRemind = @"BookOrderStartRemind:"; //BookOrderStartRemind还有十分钟订单开始提醒
static NSString *const  BookOrderTimeout = @"BookOrderTimeout:"; //BookOrderTimeout订单无译员接单
static NSString *const  BookOrderUserMiss = @"BookOrderUserMiss:"; //BookOrderUserMiss用户爽约推送
static NSString *const  BookOrderTrDutyCancel = @"BookOrderTrDutyCancel:"; //译员有责取消
static NSString *const  BookOrderTrNoDutyCancel = @"BookOrderTrNoDutyCancel:"; //译员无则取消
static NSString *const  BookOrderTrMiss = @"BookOrderTrMiss:"; //译员爽约推送
static NSString *const  BookOrderConnectionFailed = @"BookOrderConnectionFailed:"; //译员爽约推送

#pragma mark TRReservationManager对象生成的预约单的通知
static NSString *const  MicroOrderLeaveMsg = @"microOrderLeaveMsg:"; //收到译员发送的留言

@interface TRNotification : NSObject

+ (instancetype)sharedManager;
/**
 typeString 上面定义的宏
 */
-(NSString *)notificationNameForTypeString:(NSString *)typeString;

/**
 name 上面定义的宏
 */
-(void)postNotificationName:(NSString *)name object:(id)object userInfo:(NSDictionary *)info;
@end
