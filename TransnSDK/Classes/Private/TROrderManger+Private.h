//
//  TROrderManger+Private.h
//  TransnSDK
//
//  Created by Fan Lv on 16/10/27.
//  Copyright © 2016年 Transn. All rights reserved.
//

#import "TROrderManger.h"
@interface TROrderManger (Private)

- (void)hangupVoiceCall;

-(void)startFlow:(NSString *)flowId linkType:(NSString *)linkType;

#pragma mark  发送Tips 消息大全
//通话中被挂断，补发挂断消息。
-(TRMessage *)sendHungUpTip;

//杀死了app
-(TRMessage *)sendKillAppTip;
//IM30秒超时
-(TRMessage *)sendIMTimeOutTip;
//用户取消订单
-(TRMessage *)sendUserCancleOrderTip;
//预扣费检查
-(TRMessage *)sendBalanceCheckResultTips:(NSString *)tips;
//确认订单
-(TRMessage *)sendUserConfirmTheOrderTip;
//支持短语音
-(TRMessage *)sendSupportVoiceTip;
//心跳包
- (TRMessage *)sendHeartBreakTip;
//用户使用语音通话
-(void)sendUserUseVoiceTip;
//用户退出语音通话
-(void)sendUserExitVoiceTip;

//系统tips
- (void)sendSystemTip:(NSString *)text;
///发送tips 消息
-(TRMessage *)sendTip:(NSString *)tips;

- (void)sendTipMessage:(NSString *)tipStr toUser:(NSString *)userID flowdID:(NSString *)fid tryTime:(int)tryTime;

-(void)handleAdminMessage:(XMPPMessage *)message;
@end
