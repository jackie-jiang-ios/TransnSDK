//
//  TROrderManger+Private.m
//  TransnSDK
//
//  Created by Fan Lv on 16/10/27.
//  Copyright © 2016年 Transn. All rights reserved.
//

#import "TROrderManger+Private.h"
#import "AgoraManger.h"
#import "TransnSDK+Private.h"
#import "XMPPManager.h"
#import "TRNetWork.h"
#import "TRBaseModel.h"
#import "TRPrivateConstants.h"

@implementation TROrderManger (Private)

#pragma mark   判断是否有通话，有的话挂断电话

- (void)hangupVoiceCall
{
    [[AgoraManger sharedInstance] hangUp];
}



-(void)startFlow:(NSString *)flowId linkType:(NSString *)linkType{
   
    if ([self.currentOrder.flowId isEqualToString:flowId]) {
        //是留言单
    }else{
        //新的订单
        self.currentOrder = nil;
        TROrder *order = [[TROrder alloc] init];
        self.currentOrder = order;
    }
    self.currentOrder.flowId = flowId;
    self.currentOrder.linkType = linkType;
  
}


#pragma mark  发送Tips 消息大全
//通话中被挂断，补发挂断消息。
-(TRMessage *)sendHungUpTip{
    return [self sendTip:HangUpTip];
}

//杀死了app
-(TRMessage *)sendKillAppTip{
    return [self sendTip:IkillTheApp];
}
//IM30秒超时
-(TRMessage *)sendIMTimeOutTip{
    return [self sendTip:Iam30sTimeOut];
}
//用户取消订单
-(TRMessage *)sendUserCancleOrderTip{
    if (!self.currentOrder.translator.translatorId) {
        [self sendUserCancelTheOrderByGetTranslatorInfoWithTryCount:5 andFlowID:self.currentOrder.flowId];// 没收到译员ID，我要获取译员ID告诉对方我取消了
        return nil;
    }
    return [self sendTip:UserCancelTheOrder];
}
//预扣费检查
-(TRMessage *)sendBalanceCheckResultTips:(NSString *)tips{
    NSString *sendStr = [NSString stringWithFormat:@"%@%@",BalanceCheckResult,tips];
    return [self sendTip:sendStr];
}
//确认订单
-(TRMessage *)sendUserConfirmTheOrderTip{
    if (self.delegate==nil) {
        [[TransnSDK shareManger] printLog:@"注意,TransnSDKChatDelegate为nil"];
    }
    return [self sendTip:UserConfirmTheOrder];
}
//支持短语音
-(TRMessage *)sendSupportVoiceTip{
    return [self sendTip:isSupportVoice];
}
//心跳包
- (TRMessage *)sendHeartBreakTip
{
    return [self sendTipMessage:IolHeartBreak toUser:self.currentOrder.translator.translatorId flowdID:self.currentOrder.flowId];
}
//用户使用语音通话
-(void)sendUserUseVoiceTip{
    [self sendTipMessage:UserUseVoiceCallingTranslator toUser:self.currentOrder.translator.translatorId flowdID:self.currentOrder.flowId tryTime:3];
    self.currentOrder.linkType = LinkType_Agora;
}
//用户退出语音通话
-(void)sendUserExitVoiceTip{
    [self sendTipMessage:UserExitVoice toUser:self.currentOrder.translator.translatorId flowdID:self.currentOrder.flowId tryTime:3];
    self.currentOrder.linkType = @"chat";
}

//系统tips
- (void)sendSystemTip:(NSString *)text
{
    [self sendTip:[NSString stringWithFormat:@"SystemMessage:%@", text]];
}

///发送tips 消息
-(TRMessage *)sendTip:(NSString *)tips{
    if (!self.currentOrder.translator.translatorId || !self.currentOrder.flowId) {
        return nil;
    }
    return [self sendTipMessage:tips toUser:self.currentOrder.translator.translatorId flowdID:self.currentOrder.flowId];
}

- (void)sendTipMessage:(NSString *)tipStr toUser:(NSString *)userID flowdID:(NSString *)fid tryTime:(int)tryTime
{
    if (tryTime > 0) {
        [self sendTipMessage:tipStr toUser:userID flowdID:fid];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self sendTipMessage:tipStr toUser:userID flowdID:fid tryTime:tryTime - 1];
        });
    }
}
// 以免重新叫单的时候新的ID覆盖了这个老的ID
- (TRMessage *)sendTipMessage:(NSString *)tipStr toUser:(NSString *)userID flowdID:(NSString *)fid
{
    if ([tipStr isEqualToString:UserCancelTheOrder]) {
        [[TransnSDK shareManger] writeToast:[NSString stringWithFormat:@"发送 取消通话 tips消息，to：%@，tempFlowid：%@", userID, fid]];
    } else if ([tipStr isEqualToString:HangUpTip]) {
        [[TransnSDK shareManger] writeToast:[NSString stringWithFormat:@"发送 挂断通话 tips消息，to：%@，tempFlowid：%@", userID, fid]];
    } else if ([tipStr isEqualToString:UserExitVoice]) {
        [[TransnSDK shareManger] writeToast:[NSString stringWithFormat:@"发送 挂断语音 tips消息，to：%@，tempFlowid：%@", userID, fid]];
    } else if ([tipStr isEqualToString:IolHeartBreak]) {
        // 发送心跳包
        //        [[TransnSDK shareManger] writeToast:[NSString stringWithFormat:@"发送 tips消息:%@", IolHeartBreak]];
    } else {
        [[TransnSDK shareManger] writeToast:[NSString stringWithFormat:@"发送 tips消息:%@", tipStr]];
    }
    
    XMPPMessage *xmppMsg = [[XMPPManager sharedInstance] newMessageWithBody:tipStr subject:XMPP_MessageType_Tip to:userID flowdID:fid];
    [[XMPPManager sharedInstance] sendMessage:xmppMsg];
    TRMessage *msg = [[TRMessage alloc] initWithMessage:xmppMsg];
    msg.sendState = TIMMessageSendStateSending;
    return msg;
}
- (void)sendUserCancelTheOrderByGetTranslatorInfoWithTryCount:(int)tryCount andFlowID:(NSString *)flowId
{
    if ((tryCount < 0) || ([flowId length] == 0)) {
        return;
    }
    
    tryCount--;
    
    NSDictionary *dic = TRDicWithOAndK(flowId, @"flowId");
    [[TRNetWork sharedManager] requestURLPath:ST_API_getTranslatorByFlowId httpMethod:TRRequestMethodPost parmas:dic completetion:^(id responseObject, NSError *error) {
        TRBaseModel *model = [[TRBaseModel alloc] initWithDictionary:responseObject];
        NSString *translatorId = [NSString stringWithFormat:@"%@", [model.data objectForKey:@"translatorId"]];
        
        NSString *isFinish = [NSString stringWithFormat:@"%@", [model.data objectForKey:@"isFinish"]];
        
        if (model.isStatusOK && ([translatorId length] > 0)) {
            [self sendTipMessage:UserCancelTheOrder toUser:translatorId flowdID:flowId];
        } else {
            if ([isFinish isEqualToString:@"0"]) {
                double delayInSeconds = 3;
                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
                    [self sendUserCancelTheOrderByGetTranslatorInfoWithTryCount:tryCount andFlowID:flowId];
                });
            }
        }
    }];
}

#pragma mark  收到admin消息
-(void)handleAdminMessage:(XMPPMessage *)message{
    if ([message.body hasPrefix:@"uploadlog"]) {//上传日志
        NSString    *fileName = @"";
        NSString    *date = @"";
        
        if ([message.body hasPrefix:@"uploadloge-"]) {
            date = [message.body stringByReplacingOccurrencesOfString:@"uploadloge-" withString:@""];
            fileName = [NSString stringWithFormat:@"%@_exception_%@.txt", [TransnSDK shareManger].myUserID, date];
        } else if ([message.body hasPrefix:@"uploadlogr-"]) {
            date = [message.body stringByReplacingOccurrencesOfString:@"uploadlogr-" withString:@""];
            fileName = [NSString stringWithFormat:@"%@_recetMsgs_%@.txt", [TransnSDK shareManger].myUserID, date];
        } else if ([message.body hasPrefix:@"uploadlogt-"]) {
            date = [message.body stringByReplacingOccurrencesOfString:@"uploadlogt-" withString:@""];
            fileName = [NSString stringWithFormat:@"%@_totst_%@.txt", [TransnSDK shareManger].myUserID, date];
        } else if ([message.body hasPrefix:@"uploadlogs-"]) {
            date = [message.body stringByReplacingOccurrencesOfString:@"uploadlogs-" withString:@""];
            fileName = [NSString stringWithFormat:@"%@_sendtMsgs_%@.txt", [TransnSDK shareManger].myUserID, date];
        }
        
        NSArray         *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        NSString        *homePath = [paths objectAtIndex:0];
        NSString        *filePath = [homePath stringByAppendingPathComponent:fileName];
        NSFileManager   *fileManager = [NSFileManager defaultManager];
        
        if (![fileManager fileExistsAtPath:filePath]) { // 如果不存在
            XMPPMessage *msg = [[XMPPMessage alloc] initWithType:@"chat" to:message.from];
            [msg addAttributeWithName:@"from" stringValue:[XMPPManager sharedInstance].myJID.full];
            [msg addAttributeWithName:XMPP_Attribute_MessageID stringValue:[NSString stringWithFormat:@"%d", arc4random()]];
            [msg addBody:@"NothisFile"];
            
            [[XMPPManager sharedInstance] sendMessage:msg];
        } else {
            NSData      *filedata = [NSData dataWithContentsOfFile:filePath];
            XMPPMessage *msg = [[XMPPMessage alloc] initWithType:@"chat" to:message.from];
            [msg addAttributeWithName:@"from" stringValue:[XMPPManager sharedInstance].myJID.full];
            [msg addAttributeWithName:XMPP_Attribute_MessageID stringValue:[NSString stringWithFormat:@"%d", arc4random()]];
            [msg addBody:[NSString stringWithFormat:@"data-length: %lu", (unsigned long)[filedata length]]];
            
            [[XMPPManager sharedInstance] sendMessage:msg];
            
            [[TransnSDK shareManger] uploadData:filedata fileName:nil withExtention:@"txt" completionHandler:^(NSString *fileUrl, NSError *error) {
                XMPPMessage *msg = [[XMPPMessage alloc] initWithType:@"chat" to:message.from];
                [msg addAttributeWithName:@"from" stringValue:[XMPPManager sharedInstance].myJID.full];
                [msg addAttributeWithName:XMPP_Attribute_MessageID stringValue:[NSString stringWithFormat:@"%d", arc4random()]];
                [msg addBody:[NSString stringWithFormat:@"data url: %@", fileUrl]];
                
                [[XMPPManager sharedInstance] sendMessage:msg];
                
                if (([fileUrl length] == 0) && ([filedata length] < 1000 * 200)) {
                    NSString *contentStr = [[NSString alloc] initWithData:filedata encoding:NSUTF8StringEncoding];
                    XMPPMessage *msg = [[XMPPMessage alloc] initWithType:@"chat" to:message.from];
                    [msg addAttributeWithName:@"from" stringValue:[XMPPManager sharedInstance].myJID.full];
                    [msg addAttributeWithName:XMPP_Attribute_MessageID stringValue:[NSString stringWithFormat:@"%d", arc4random()]];
                    [msg addBody:contentStr];
                    [[XMPPManager sharedInstance] sendMessage:msg];
                }
            }];
        }
    }
}
@end
