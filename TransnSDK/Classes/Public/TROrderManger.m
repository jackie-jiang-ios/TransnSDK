//
//  TROrderManger.m
//  TransnSDK
//
//  Created by Fan Lv on 16/10/27.
//  Copyright © 2016年 Transn. All rights reserved.
//

#import "TROrderManger.h"
#import "AgoraManger.h"
#import "XMPPManager.h"

#import "TransnSDK+Private.h"
#import "TROrderManger+Private.h"
#import "TROrder+Private.h"
#import "TRMessage.h"

#import "TRBaseModel.h"
#import "NSManagedObject+TExtension.h"

#import "TRNetWork.h"
#import "TRPrivateConstants.h"
#import "NSObject+TRKeyValue.h"
#import "NSXMLElement+XEP_0203.h"
#import "TRNotification.h"
@interface TROrderManger ()
{
    NSTimer     *_checkXMPPTimeOutTimer;                // XMPP内部心跳包30秒没连上，就断开
    NSTimer     *_checkTranserOnLineHeartBreakTimer;    // 每1秒检测译员端发送过来的心跳包，超过30秒则挂断
    int         _checkXMPPTimeOutTimerflag;
    BOOL        isXmppDisConnected;
    NSString    *_userSDKVersion;
    
    // 30秒心跳包保活，记录的开始时间和结束时间
    NSDate  *_keepAlive_receviceDate;

    NSString *translatorId;//译员ID
}


@end

@implementation TROrderManger
#pragma mark - Propety

//- (XMPPJID *)remoteJID
//{
//    return [XMPPJID jidWithUser:self.currentOrder.translator.translatorId domain:[XMPPManager sharedInstance].XMPP_DOMAIN resource:XMPP_Resource];
//
#pragma mark TRAPIDeprecated
- (BOOL)isConnected
{
    return self.currentOrder.isConnected;
}
-(NSString *)flowId{
    return self.currentOrder.flowId;
}
-(NSString *)linkType{
    return self.currentOrder.linkType;
}

-(TRTranslator *)translator{
    if (self.currentOrder.translator==nil&&translatorId) {
        [[TransnSDK shareManger] writeToast:@"bug，有译员ID，没有译员对象"];
    }
    return self.currentOrder.translator;
}

-(int)currentOrderTime{
    return self.currentOrder.orderTime;
}



#pragma mark - Init

- (id)init
{
    self = [super init];
    
    if (self) {
        [self initBlocks];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(imConnectStateChange:)
                                                     name:IM_Connect_State_Change object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillTerminate:)
                                                     name:UIApplicationWillTerminateNotification object:nil];
    }
    
    return self;
}

- (void)initBlocks
{
    __weak __typeof(self) weakSelf = self;
    
    [XMPPManager sharedInstance].didSendMessage = ^(XMPPMessage *message) {
        [weakSelf didSendMessage:message];
    };
    
    [XMPPManager sharedInstance].didReceiveMessage = ^(XMPPMessage *message) {
        [weakSelf didReceiveMessage:message];
    };
    
    [XMPPManager sharedInstance].didFailToSendMessage = ^(XMPPMessage *message) {
        [weakSelf didFailToSendMessage:message];
    };
    
    
    [AgoraManger sharedInstance].callStatusdidLeaveChannelWithStats = ^(AgoraChannelStats *stats) {
        [weakSelf voiceDidDisConnected];
        NSString *durationMsg = [NSString stringWithFormat:@"duration %lu", (unsigned long)stats.duration];
        [[TransnSDK shareManger] uploadErrorLog:@"通话时长" expMsg:durationMsg flowId:weakSelf.currentOrder.flowId];
    };
    
    [AgoraManger sharedInstance].callDidDisconnected = ^() {
        [weakSelf voiceDidDisConnected];
    };
    
    [AgoraManger sharedInstance].callDidconnected = ^() {
        [weakSelf voiceDidConnected];
    };
    
    [AgoraManger sharedInstance].audioQuality = ^(NSUInteger quality) {
        [weakSelf audioQuality:quality];
    };
}

- (void)setDelegate:(id <TransnSDKChatDelegate>)delegate
{
    _delegate = delegate;
    
    if (delegate == nil) {
        [[TransnSDK shareManger] printLog:@"设置delegate为nil"];
    } else {
        [[TransnSDK shareManger] printLog:@"设置delegate了"];
    }
}


//TransnBox 呼单方法，在transnBox项目中，使用的接口是
- (void)callTransnBoxWithFlowId:(NSString *)flowId{
    [self startFlow:flowId linkType:LinkType_TransnBox];
}



#pragma mark 收到Tips 消息
-(NSString *)tipsType:(XMPPMessage *)message{
    [[TransnSDK shareManger] printLog:message.body];
    if ([[message.body lowercaseString] hasPrefix:[BookOrderReceived lowercaseString]]) {
        return BookOrderReceived;
    }else if([[message.body lowercaseString] hasPrefix:[BookOrderStartRemind lowercaseString]]){
        return BookOrderStartRemind;
    }else if([[message.body lowercaseString] hasPrefix:[BookOrderTimeout lowercaseString]]){
        return BookOrderTimeout;
    }else if([[message.body lowercaseString] hasPrefix:[BookOrderUserMiss lowercaseString]]){
        return BookOrderUserMiss;
    }else if([[message.body lowercaseString] hasPrefix:[HwStatusMsg lowercaseString]]){
        return HwStatusMsg;
    }else if([[message.body lowercaseString] hasPrefix:[ReCallUser lowercaseString]]){
        return ReCallUser;
    }else if([[message.body lowercaseString] hasPrefix:[CollectTransOnLine lowercaseString]]){
        return CollectTransOnLine;
    }else if([[message.body lowercaseString] hasPrefix:[BookOrderTrDutyCancel lowercaseString]]){
        return BookOrderTrDutyCancel;
    }else if([[message.body lowercaseString] hasPrefix:[BookOrderTrNoDutyCancel lowercaseString]]){
        return BookOrderTrNoDutyCancel;
    }else if([[message.body lowercaseString] hasPrefix:[BookOrderTrMiss lowercaseString]]){
        return BookOrderTrMiss;
    }else if([[message.body lowercaseString] hasPrefix:[BookOrderConnectionFailed lowercaseString]]){
        return BookOrderConnectionFailed;
    }else if([[message.body lowercaseString] hasPrefix:[MicroOrderLeaveMsg lowercaseString]]){
        return MicroOrderLeaveMsg;
    }
    
    return nil;
}
 

- (void)handleIMTipsMessage:(XMPPMessage *)message
{

    NSString    *flowIdINremoteExt = message.thread;
    NSString    *fromUserId = message.from.user;
     if ([[message.body lowercaseString] hasPrefix:[IolHeartBreak lowercaseString]]) {
        _keepAlive_receviceDate = [NSDate date];
        return;
    }else if ([[message.body lowercaseString] hasPrefix:[TransnerInfo lowercaseString]]) {
        //老版本，先放着
        NSString        *infoStr = [message.body stringByReplacingOccurrencesOfString:TransnerInfo withString:@""];
        NSDictionary    *dic = [infoStr tr_JSONObject];
        NSString        *callBackType = [dic objectForKey:@"callBackType"];
        translatorId = message.from.user;
        if (!self.delegate && [callBackType isEqualToString:@"1"]) {
             [self gotTranslatorInfo:dic];
            [[TRNotification sharedManager] postNotificationName:IM_Chat_Receive_Call object:infoStr userInfo:dic];
            return;
        }
    }
    /////
   else if ([[message.body lowercaseString] hasPrefix:[BaiduPreCharge lowercaseString]]) {
        [self getPreCharge:message];
        return;
    }else if([self tipsType:message].length){//主要是transnBox和小尾巴 tips消息
        NSString *tipType = [self tipsType:message];
        NSString        *infoStr = [message.body stringByReplacingOccurrencesOfString:tipType withString:@""];
        NSDictionary    *dic = [infoStr tr_JSONObject];
        [[TRNotification sharedManager] postNotificationName:tipType object:infoStr userInfo:dic];
        return;
    }
    if (self.currentOrder.linkType == LinkType_TransnBox) {
        if (_delegate && [_delegate respondsToSelector:@selector(onRecvTransnBoxTipsMessages:)]) {
            TRMessage *mMsg = [[TRMessage alloc] initWithMessage:message];
            [_delegate onRecvTransnBoxTipsMessages:mMsg];
        }
        return;
    }
    
    if ([flowIdINremoteExt isEqualToString:self.currentOrder.flowId]) {                                  // flowId相同表示同一个订单才能执行下面逻辑
        if ([[message.body lowercaseString] isEqualToString:[HangUpTip lowercaseString]]) { // 收到挂断电话消息
            if (self.currentOrder.isConnected) {
                [[TransnSDK shareManger] printLog:@"收到对方给我发的挂断电话自定义消息"];
                [self httpServerHangUp:TRTransComplete];
            }
        } else if ([message.body isEqualToString:@"FinishabNormalCall"]) {//有一方异常中断了，服务器告诉另一方挂断电话
            if (self.currentOrder.isConnected) {
                [self httpServerHangUp:TRServerSensorTransIMOffLine];
                TRLog(@"服务器通知SDK这段通话结束---服务端感知译员掉线挂断");
                [[TransnSDK shareManger] uploadErrorLog:@"服务异常结束" expMsg:@"服务器通知SDK这段通话结束" flowId:self.currentOrder.flowId];
            }
        } else if ([[message.body lowercaseString] hasPrefix:[Iam30sTimeOut lowercaseString]]) {
            [[TransnSDK shareManger] printLog:@"收到对方给我发的IM断线30s消息"];
            [self httpServerHangUp:TRTransIMOffLine];
        } else if ([[message.body lowercaseString] hasPrefix:[IkillTheApp lowercaseString]]) {
            [[TransnSDK shareManger] printLog:@"收到对方给我发的杀掉进程消息"];
            [self httpServerHangUp:TRTransAppKill];
        }
        /////2017-10-20 订单优化，姜政修改
        else if ([[message.body lowercaseString] hasPrefix:[TransaltorAcceptedOrder lowercaseString]]) {// 收到译员图像和用户名称信息
            translatorId = message.from.user;
            NSString        *infoStr = [message.body stringByReplacingOccurrencesOfString:TransaltorAcceptedOrder withString:@""];
            NSDictionary    *dic = [infoStr tr_JSONObject];
//            NSString        *callBackType = [dic objectForKey:@"callBackType"];
            [self gotTranslatorInfo:dic];
            ///不在接单界面 发送接单消息等待用户领取订单
            //delegate 为空，就位留言单 20180328
            if (!self.delegate) {
                return;
            } else {
                [self gotTranslator];
            }
            [TRTranslator insertItemWithDict:dic];
        } else if ([[message.body lowercaseString] hasPrefix:[CallingUserTip lowercaseString]]) {
            translatorId = message.from.user;
            //老版本，不处理了
        } else if ([[message.body lowercaseString] hasPrefix:[ResponseCallError lowercaseString]]) {
            if (self.delegate && [self.delegate respondsToSelector:@selector(bulidLineWithErrorString:)]) {
                [[TransnSDK shareManger] uploadErrorLog:@"建立通话失败" expMsg:@"收到对方给我发的接听电话异常的自定义消息" flowId:self.currentOrder.flowId];
            }
            
            [self callConnectWithErrorMessage:NSLocalizedString(@"建立通话失败", @"建立通话失败") connectType:0];
        } else if ([message.body isEqualToString:@"TimeoutStartCancel"]) {// 订单超时，服务器通知客户端失效
            if (self.delegate && [self.delegate respondsToSelector:@selector(bulidLineWithErrorString:)]) {
                [[TransnSDK shareManger] printLog:@"TimeoutStartCancel 服务器通知客户端失效"];
                [[TransnSDK shareManger] uploadErrorLog:@"订单超时" expMsg:@"TimeoutStartCancel 服务器通知客户端失效" flowId:self.currentOrder.flowId];
            }
            
            [self callConnectWithErrorMessage:NSLocalizedString(@"订单超时", @"订单超时") connectType:0];
        }
    } else {
        if ([message.body hasPrefix:@"uploadlog"]) {
            // donoth;
        } else if ([message.body isEqualToString:@"FinishabNormalCall"]) {//有一方异常中断了，服务器告诉另一方挂断电话
            [[TransnSDK shareManger] printLog:@"服务器通知会话结束"];
        } else if ([[message.body lowercaseString] hasPrefix:[HangUpTip lowercaseString]]) {
            [[TransnSDK shareManger] printLog:@"译员已经结束会话"];
        } else {
            // 主动挂断消息，译员端会发送HangUpTip消息给SDK，进这个方法
            [[TransnSDK shareManger] printLog:[NSString stringWithFormat:@"_flowId 不匹配 ： %@", message]];
        }
    }
    
    if ([[fromUserId lowercaseString] hasPrefix:@"admin"]) {
        [self handleAdminMessage:message];
    }
}

// 预翻译
- (void)getPreCharge:(XMPPMessage *)message
{
    NSString        *infoStr = [message.body stringByReplacingOccurrencesOfString:BaiduPreCharge withString:@""];
    NSDictionary    *dic = [infoStr tr_JSONObject];
    if (_delegate && [_delegate respondsToSelector:@selector(onRecvPreTranslate:canTranslate:)]) {
        [_delegate onRecvPreTranslate:dic canTranslate:^(BOOL canTranslate) {
            NSMutableDictionary *param = [NSMutableDictionary dictionaryWithDictionary:dic];
            if (canTranslate) {
               [param setObject:@"true" forKey:@"checkResult"];
                TRLog(@"可以翻译");
            } else {
                [param setObject:@"false" forKey:@"checkResult"];
                TRLog(@"不能翻译");
            }
        
            [self sendBalanceCheckResultTips:param.tr_JSONString];
            NSDictionary *postParam = TRDicWithOAndK(self.currentOrder.flowId,@"flowId",dic[@"src_messageId"],@"srcMsgId",canTranslate?@"true":@"false",@"checkResult",self.currentOrder.translator.translatorId,@"translatorId");
            [[TRNetWork sharedManager] requestURLPath:ST_API_conversation_sendAuthResult2Server httpMethod:TRRequestMethodPost parmas:postParam completetion:nil];
        }];
    }
   
}

- (void)userReceiveTheCall
{
    ///不在接单界面 发送接单消息等待用户领取订单
    [self gotTranslator];
}

#pragma mark - 消息回调

- (void)didSendMessage:(XMPPMessage *)message
{
    if ([message.subject isEqualToString:XMPP_MessageType_Text] || [message.subject isEqualToString:XMPP_MessageType_Image] || [message.subject isEqualToString:XMPP_MessageType_Voice]) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(sendMessage:didCompleteWithState:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                TRMessage *msg = [[TRMessage alloc] initWithMessage:message];
                msg.sendState = TIMMessageSendStateSuccess;
                [self.delegate sendMessage:msg didCompleteWithState:msg.sendState];
                
                if ([message.subject isEqualToString:XMPP_MessageType_Image]) {
                    // 如果是图片消息，就把image至为nil，减少内存消耗
                    msg.image = nil;
                }
                if ([TRMessageStorage sharedStorage].messageStoreMode == TRMessageStoreAll || [TRMessageStorage sharedStorage].messageStoreMode == TRMessageStoreDefault) {
                    [TRMessageManagedObject updateMessage:msg state:TIMMessageSendStateSuccess time:5 flowId:self.currentOrder.flowId userId:[TransnSDK shareManger].clientID];
                }
            });
         
            
        }
    } else if ([message.subject isEqualToString:XMPP_MessageType_Tip]) {
        //        TRLog(@"message.body :%@",message.body);
    }
    
    if ([message hasChatState] == NO) {
        [[XMPPManager sharedInstance] writeSendMessage:message];
    }
}

- (void)didFailToSendMessage:(XMPPMessage *)message
{
    if ([message.subject isEqualToString:XMPP_MessageType_Text] || [message.subject isEqualToString:XMPP_MessageType_Image] || [message.subject isEqualToString:XMPP_MessageType_Voice]) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(sendMessage:didCompleteWithState:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                TRMessage *msg = [[TRMessage alloc] initWithMessage:message];
                msg.sendState = TIMMessageSendStatefail;
                [self.delegate sendMessage:msg didCompleteWithState:msg.sendState];
                
                if ([message.subject isEqualToString:XMPP_MessageType_Image]) {
                    // 如果是图片消息，就把image至为nil，减少内存消耗
                    msg.image = nil;
                }
                if ([TRMessageStorage sharedStorage].messageStoreMode == TRMessageStoreAll || [TRMessageStorage sharedStorage].messageStoreMode == TRMessageStoreDefault) {
                    [TRMessageManagedObject updateMessage:msg state:TIMMessageSendStatefail time:5 flowId:self.currentOrder.flowId userId:[TransnSDK shareManger].clientID];
                }
            });
        }
    } else if ([message.subject isEqualToString:XMPP_MessageType_Tip]) {
        double          delayInSeconds = 2;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
            [[XMPPManager sharedInstance] sendMessage:message];
        });
    }
}

NSMutableArray *alreadyReceMessageID;
// 接收消息
- (void)didReceiveMessage:(XMPPMessage *)message
{
    TRMessage *mMsg = [[TRMessage alloc] initWithMessage:message];
    
    NSDate *timestamp = [message delayedDeliveryDate];
    
    if (timestamp) {
        mMsg.timestamp = timestamp;
    } else {
        mMsg.timestamp = [NSDate date];
    }
    
    if (alreadyReceMessageID == nil) {
        alreadyReceMessageID = [[NSMutableArray alloc] init];
    }
    
    if ([mMsg.messageID length] > 0) {
        if (![alreadyReceMessageID containsObject:mMsg.messageID]) {
            [alreadyReceMessageID addObject:mMsg.messageID];
        } else {
            [[TransnSDK shareManger] printLog:[NSString stringWithFormat:@"重复收到已有消息 %@", message]];
            return;
        }
    }
    
    if ([message.subject isEqualToString:XMPP_MessageType_Image] || [message.subject isEqualToString:XMPP_MessageType_Text] || [message.subject isEqualToString:XMPP_MessageType_Voice] || [message.subject isEqualToString:XMPP_MessageType_PaymentMessage] || [message.subject isEqualToString:XMPP_MessageType_RecommendMessage]) {
        NSString *flowIdINremoteExt = message.thread;
        
        if ([self.currentOrder.flowId isEqualToString:flowIdINremoteExt] == NO) {
            if (self.currentOrder.flowId == nil) {
                // 会话已经结束
            } else {
                [[TransnSDK shareManger] printLog:[NSString stringWithFormat:@"flowId不匹配不处理这个文本消息 %@ ： %@", self.currentOrder.flowId, message]];
            }
            
            return;
        }
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(onRecvMessages:)]) {
            mMsg.translatorMb = self.currentOrder.translator;
            if (!mMsg.translatorMb) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    mMsg.translatorMb =  [TRTranslator managedObjectWithTranslatorId:message.from.user];;
                });
            }
            
            if (self.checkRecvMsgSensitiveWords) {
                if ((mMsg.messageType == TIMMessageTypeText) || ((mMsg.messageType == TIMMessageTypePaymentMessage) && !((mMsg.paymentMessageType == PaymentMsgTypeImage2Voice) || (mMsg.paymentMessageType == PaymentMsgTypeVoice2Voice)))) {
                    // 含有text类型的才监测敏感词
                    [self checkSensitiveWords:mMsg completion:^{
                        [self.delegate onRecvMessages:mMsg];
                    }];
                } else {
                    [self.delegate onRecvMessages:mMsg];
                }
            } else {
                [self.delegate onRecvMessages:mMsg];
            }
            if ([TRMessageStorage sharedStorage].messageStoreMode == TRMessageStoreAll || [TRMessageStorage sharedStorage].messageStoreMode == TRMessageStoreDefault) {
                 [TRMessageManagedObject updateMessage:mMsg state:TIMMessageSendStateSuccess time:0 flowId:self.currentOrder.flowId userId:[TransnSDK shareManger].clientID];
            }
          
        }
    } else if ([message hasChatState]) {
        if ([message hasComposingChatState]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:IM_Chat_State_Composing object:nil];
        } else if ([message hasPausedChatState]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:IM_Chat_State_Paused object:nil];
        } else {
            //            TRLog(@"message %@",message);
        }
    } else if ([message.subject isEqualToString:XMPP_MessageType_Tip] || [message.from.user hasPrefix:@"admin"]) {
        [self handleIMTipsMessage:message];
    }
    
    if ([message hasChatState] == NO) {
        [[XMPPManager sharedInstance] writeRecvMessage:message];
    }
}

#pragma mark - 发送消息

- (void)sendComposingChatToUser
{
    [[XMPPManager sharedInstance] sendComposingChatToUser:self.currentOrder.translator.translatorId];
}

- (void)sendPausedChatToUser
{
    [[XMPPManager sharedInstance] sendPausedChatToUser:self.currentOrder.translator.translatorId];
}

-(BOOL)canSendMessage{
    //接单前发送消息，不发送
    if (!self.currentOrder.isConnected) {
        return NO;
    }else if(!self.currentOrder.translator||self.currentOrder.translator.translatorId.length==0){
        return NO;
    }
    return YES;
}
- (TRMessage *)sendTextMessage:(NSString *)text
{
    NSError *aError = [[TransnSDK shareManger] checkAppIDAndAppSecretAvaliable];
    
    if (aError) {
        return nil;
    }
    
    XMPPMessage *xmppMsg = [[XMPPManager sharedInstance] newMessageWithBody:text subject:XMPP_MessageType_Text to:self.currentOrder.translator.translatorId flowdID:self.currentOrder.flowId];
    if ([self canSendMessage]) {
        [[XMPPManager sharedInstance] sendMessage:xmppMsg];
    }
    TRMessage *msg = [[TRMessage alloc] initWithMessage:xmppMsg];
    msg.translatorMb = self.currentOrder.translator;
    msg.sendState = TIMMessageSendStateSending;
    msg.timestamp = [NSDate date];
    
    // 检测敏感词
    if (self.checkSendMsgSensitiveWords) {
        [self checkSensitiveWords:msg completion:nil];
    }
    if ([TRMessageStorage sharedStorage].messageStoreMode == TRMessageStoreAll || [TRMessageStorage sharedStorage].messageStoreMode == TRMessageStoreDefault) {
        [TRMessageManagedObject updateMessage:msg state:TIMMessageSendStateSending time:0 flowId:self.currentOrder.flowId userId:[TransnSDK shareManger].clientID];
    }
    return msg;
}

- (TRMessage *)sendImageMessage:(UIImage *)img
{
    NSError *aError = [[TransnSDK shareManger] checkAppIDAndAppSecretAvaliable];
    
    if (aError) {
        return nil;
    }
    
    XMPPMessage *xmppMsg = [[XMPPManager sharedInstance] newMessageWithBody:@""
                                                                   subject :XMPP_MessageType_Image
                                                                   to:self.currentOrder.translator.translatorId
                                                                   flowdID :self.currentOrder.flowId];
    TRMessage *msg = [[TRMessage alloc] initWithMessage:xmppMsg];
    msg.translatorMb = self.currentOrder.translator;
    msg.sendState = TIMMessageSendStateSending;
    msg.timestamp = [NSDate date];
    msg.image = img;
    
    [self uploadImageAndSendMessage:msg];
    
    if ([TRMessageStorage sharedStorage].messageStoreMode == TRMessageStoreAll || [TRMessageStorage sharedStorage].messageStoreMode == TRMessageStoreDefault) {
        [TRMessageManagedObject updateMessage:msg state:TIMMessageSendStateSending time:0 flowId:self.currentOrder.flowId userId:[TransnSDK shareManger].clientID];
    }
    return msg;
}

- (TRMessage *)sendVoiceMessage:(NSString *)filePath voiceSize:(NSString *)voiceSize
{
    NSError *aError = [[TransnSDK shareManger] checkAppIDAndAppSecretAvaliable];
    
    if (aError) {
        return nil;
    }
    
    XMPPMessage *xmppMsg = [[XMPPManager sharedInstance] newMessageWithBody:@""
                                                                   subject :XMPP_MessageType_Voice
                                                                   to      :self.currentOrder.translator.translatorId
                                                                   flowdID :self.currentOrder.flowId];
    TRMessage *msg = [[TRMessage alloc] initWithMessage:xmppMsg];
    
    msg.translatorMb = self.currentOrder.translator;
    msg.sendState = TIMMessageSendStateSending;
    msg.timestamp = [NSDate date];
    msg.voicelocalUrl = filePath;
    msg.voiceSize = voiceSize;
    [self uploadVoiceAndSendMessage:msg];
    if ([TRMessageStorage sharedStorage].messageStoreMode == TRMessageStoreAll || [TRMessageStorage sharedStorage].messageStoreMode == TRMessageStoreDefault) {
        [TRMessageManagedObject updateMessage:msg state:TIMMessageSendStateSending time:0 flowId:self.currentOrder.flowId userId:[TransnSDK shareManger].clientID];
    }
    return msg;
}

- (void)reSendMessage:(TRMessage *)msg
{
    msg.sendState = TIMMessageSendStateSending;
    
    if ((msg.messageType == TIMMessageTypeImage) && msg.image && ([msg.imageUrl length] == 0)) {
        [self uploadImageAndSendMessage:msg];
    } else if ((msg.messageType == TIMMessageTypeVocie) && msg.voicelocalUrl && ([msg.voiceUrl length] == 0)) {
        [self uploadVoiceAndSendMessage:msg];
    } else {
        if ([self canSendMessage]) {
            [[XMPPManager sharedInstance] sendMessage:msg.exMessage];
        }
    }
}

- (void)sendSystemTipsMesssage:(NSString *)text
{
    [self sendSystemTip:text];
}

- (void)uploadImageAndSendMessage:(TRMessage *)message
{
    if (message == nil) {
        return;
    }
    
    [[TransnSDK shareManger] uploadData:UIImageJPEGRepresentation(message.image, 1.0)  fileName:nil withExtention:@"jpg" completionHandler:^(NSString *fileUrl, NSError *_Nullable error) {
        if (error || ([fileUrl length] == 0)) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (self.delegate && [self.delegate respondsToSelector:@selector(sendMessage:didCompleteWithState:)]) {
                    message.sendState = TIMMessageSendStatefail;
                    if ([TRMessageStorage sharedStorage].messageStoreMode == TRMessageStoreAll || [TRMessageStorage sharedStorage].messageStoreMode == TRMessageStoreDefault) {
                        [TRMessageManagedObject updateMessage:message state:TIMMessageSendStatefail time:5 flowId:self.currentOrder.flowId userId:[TransnSDK shareManger].clientID];
                    }
                    [self.delegate sendMessage:message didCompleteWithState:TIMMessageSendStatefail];
                }
            });
        } else {
            message.imageUrl = fileUrl;
            if ([self canSendMessage]) {
                [[XMPPManager sharedInstance] sendMessage:message.exMessage];
            }
            if (self.delegate && [self.delegate respondsToSelector:@selector(sendImageMessage:didCompleteUpdateImage:)]) {
                [self.delegate sendImageMessage:message didCompleteUpdateImage:message.image];
                message.image = nil;
            }
            
            //上面的方法会去刷新数据
        }
    }];
}

- (void)uploadVoiceAndSendMessage:(TRMessage *)message
{
    if ((message == nil) || (message.voicelocalUrl.length == 0)) {
        return;
    }
    
    NSData      *data = [NSData dataWithContentsOfFile:message.voicelocalUrl];
    NSString    *ext = @"mp3";
    
    [[TransnSDK shareManger] uploadData:data fileName:nil withExtention:ext completionHandler:^(NSString *fileUrl, NSError *_Nullable error) {
        if (error || ([fileUrl length] == 0)) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (self.delegate && [self.delegate respondsToSelector:@selector(sendMessage:didCompleteWithState:)]) {
                    message.sendState = TIMMessageSendStatefail;
                    [self.delegate sendMessage:message didCompleteWithState:TIMMessageSendStatefail];
                    if ([TRMessageStorage sharedStorage].messageStoreMode == TRMessageStoreAll || [TRMessageStorage sharedStorage].messageStoreMode == TRMessageStoreDefault) {
                        [TRMessageManagedObject updateMessage:message state:TIMMessageSendStatefail time:5 flowId:self.currentOrder.flowId userId:[TransnSDK shareManger].clientID];
                    }
                    
                }
            });
        } else {
            message.voiceUrl = fileUrl;
            if ([self canSendMessage]) {
                [[XMPPManager sharedInstance] sendMessage:message.exMessage];
            }
            //上面的方法回去刷新数据
        }
    }];
}

#pragma mark - Notification

- (void)appWillTerminate:(NSNotification *)note
{
    [[TransnSDK shareManger] printLog:@"通话中被挂断，补发挂断消息。"];
    if (self.currentOrder.isConnected) {
        int sdkVersion = [[_userSDKVersion stringByReplacingOccurrencesOfString:@"." withString:@""] intValue];
        
        if (sdkVersion >= 122) {
            [self sendKillAppTip];
        } else {
            [self sendHungUpTip];
        }
    }
}

- (void)imConnectStateChange:(NSNotification *)note
{
    if ([note.object isEqualToString:IM_Connect_State_DidConnect] || [note.object isEqualToString:IM_Connect_State_WillConnect]) {} else if ([note.object isEqualToString:IM_Connect_State_DidDisconnect]) {
        if (isXmppDisConnected) {
            isXmppDisConnected = NO;
            [_checkXMPPTimeOutTimer invalidate];
            _checkXMPPTimeOutTimer = nil;
            _checkXMPPTimeOutTimerflag = 0;
            // 开始执行新线程的Run Loop
            _checkXMPPTimeOutTimer = [NSTimer scheduledTimerWithTimeInterval:30
                target                                                      :self
                selector                                                    :@selector(checkXMPPTimeOutTimerTick:)
                userInfo                                                    :@"start"
                repeats                                                     :YES];
            [_checkXMPPTimeOutTimer fire];
            [[NSRunLoop currentRunLoop] addTimer:_checkXMPPTimeOutTimer forMode:NSRunLoopCommonModes];
            [[TransnSDK shareManger] uploadErrorLog:@"XXMPP-DidDisconnect" expMsg:@"" flowId:@""];
        }
    } else if ([note.object isEqualToString:IM_Connect_State_DidAuthenticate]) {
        [_checkXMPPTimeOutTimer invalidate];
        _checkXMPPTimeOutTimer = nil;
        isXmppDisConnected = YES;
        
        if (self.currentOrder.isConnected) {
            [TransnSDK shareManger].myOnlineState = OnlineStateBusy;
        } else {
            [TransnSDK shareManger].myOnlineState = OnlineStateOnLine;
        }
    } else if ([note.object isEqualToString:IM_Connect_State_DidNotAuthenticate]) {
        [[TransnSDK shareManger] uploadErrorLog:@"XXMPP-didNotAuthenticate" expMsg:@"" flowId:@""];
    } else if ([note.object isEqualToString:IM_Connect_State_AutoPingDidTimeout]) {
        [[TransnSDK shareManger] uploadErrorLog:@"XXMPP-PING服务器超时" expMsg:@"xmppAutoPingDidTimeout" flowId:@""];
    }
}

- (void)checkXMPPTimeOutTimerTick:(NSTimer *)theTimer
{
    if (_checkXMPPTimeOutTimerflag != 0) {
        if ([[XMPPManager sharedInstance].xmppStream isAuthenticated] == 0) {// 30s秒内还没回复
            TRLog(@"%@", @"IM掉线30s没连上");
            
            if (self.currentOrder.isConnected) {
                [[TransnSDK shareManger] uploadErrorLog:@"客户端断线" expMsg:@"IM掉线30s没连上" flowId:self.currentOrder.flowId];
                int sdkVersion = [[_userSDKVersion stringByReplacingOccurrencesOfString:@"." withString:@""] intValue];
                if (sdkVersion >= 122) {
                    [self sendIMTimeOutTip];
                } else {
                    [self sendHungUpTip];
                }
                [self httpServerHangUp:TRUserIMOffLine];
            }
        }
        
        [theTimer invalidate];
        theTimer = nil;
    }
    
    _checkXMPPTimeOutTimerflag++;
}

#pragma mark  通话相关逻辑

/**
 *  当前通话网络状态
 *  @param quality 网络状态
 */
- (void)audioQuality:(NSUInteger)quality
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(onCallNetStatus:)]) {
        [self.delegate onCallNetStatus:quality];
    }
}

- (void)callConnectWithErrorMessage:(NSString *)errorMsg connectType:(int)type
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(bulidLineWithErrorString:)]) {
        self.currentOrder.isConnected = NO;
        [self.delegate bulidLineWithErrorString:errorMsg];
    }
}

///语音连接上
- (void)voiceDidConnected
{
    [[TransnSDK shareManger] printLog:@"用户已经进入语音聊天室"];
    [self.currentOrder voiceDidConnected];
    if (self.delegate && [self.delegate respondsToSelector:@selector(voiceConnected)]) {
        [self.delegate voiceConnected];
    }
    if ((self.currentOrder.isTextOrder == NO) && (self.currentOrder.isConnected == NO)) {// 语音订单的话，通话之前没有开始，所以会进行通话开始的回调
        [self callDidconnected];
    }
}

///语音断开
- (void)voiceDidDisConnected
{
    [[TransnSDK shareManger] printLog:@"用户退出语音聊天室"];
    [self.currentOrder voiceDidDisConnected];
    if (self.delegate && [self.delegate respondsToSelector:@selector(voiceDisconnected)]) {
        [self.delegate voiceDisconnected];
    }
}

///通话连上
- (void)callDidconnected
{
    [[TransnSDK shareManger] printLog:@"用户和译员已经可以通话了"];
    [self sendUserConfirmTheOrderTip];
    if (!self.currentOrder.isConnected && self.delegate && [self.delegate respondsToSelector:@selector(netCallStatusDidconnected)]) {
        //保证不会重复调用
        self.currentOrder.isConnected = YES;
        [self.delegate netCallStatusDidconnected];
        [self sendSupportVoiceTip];
        [self startSendHeartBreak];
    }
}

- (void)checkTranserOnLine
{
    // 当前日历
    NSCalendar *calendar = [NSCalendar currentCalendar];
    // 需要对比的时间数据
    NSCalendarUnit unit = NSCalendarUnitYear | NSCalendarUnitMonth
    | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond;
    // 对比时间差
    NSDateComponents *dateCom = [calendar components:unit fromDate:_keepAlive_receviceDate toDate:[NSDate date] options:0];
    
    if (dateCom.second > 40.0) {
        if (isXmppDisConnected) {
            [self httpServerHangUp:TRUserSensorTransOffLine];
        } else {
            [self httpServerHangUp:TRUserIMOffLine];
        }
    } else {
        if (0 == self.currentOrder.orderTime % 10) {
            // 每10秒发送一次
            [self sendHeartBreakTip];
        }
    }
    
    self.currentOrder.orderTime++;
}

- (void)startSendHeartBreak
{
    /////2017-10-20 订单优化，姜政修改
    _keepAlive_receviceDate = [NSDate date];
    if (!_checkTranserOnLineHeartBreakTimer) {
        _checkTranserOnLineHeartBreakTimer = [NSTimer scheduledTimerWithTimeInterval:1
            target                                                                  :self
            selector                                                                :@selector(checkTranserOnLine)
            userInfo                                                                :nil
            repeats                                                                 :YES];
        [_checkTranserOnLineHeartBreakTimer fire];
        [[NSRunLoop currentRunLoop] addTimer:_checkTranserOnLineHeartBreakTimer forMode:NSRunLoopCommonModes];
    }
}

- (void)stopSendHeartBreak
{
    _keepAlive_receviceDate = nil;
    [_checkTranserOnLineHeartBreakTimer invalidate];
    _checkTranserOnLineHeartBreakTimer = nil;
}

- (void)gotTranslatorInfo:(NSDictionary *)transerInfo
{
    _userSDKVersion = [transerInfo objectForKey:@"version"];
    TRTranslator *translator = [[TRTranslator alloc] init];
    [translator setValuesForKeysWithDictionary:transerInfo];
    if (self.currentOrder==nil) {
        //app启动。留言单.译员回呼
        TROrder *order = [[TROrder alloc] init];
        self.currentOrder = order;
    }
     self.currentOrder.translator = translator;
}


- (void)gotTranslator
{
    [[TransnSDK   shareManger] printLog:@"译员已接单"];
    if (!self.currentOrder.isConnected && self.delegate && [self.delegate respondsToSelector:@selector(onReceiveTranslatorModel:)]) {
        [self.delegate onReceiveTranslatorModel:self.currentOrder.translator];
    } else if (!self.currentOrder.isConnected && self.delegate && [self.delegate respondsToSelector:@selector(receiveTransnerName:image:translatorId:translatorRemark:)]) {
        [self.delegate receiveTransnerName:self.currentOrder.translator.translatorName image:self.currentOrder.translator.translatorIcon translatorId:self.currentOrder.translator.translatorId translatorRemark:self.currentOrder.translator.transerInfo];
    }
    
    // 文本状态下获取到译员图像就开始通话
    if (self.currentOrder.isTextOrder) { // 文本单语音接通要给回调
        [self callDidconnected];
    } else {                // 语音单，收到译员信息，要进入聊天室
        if (self.delegate && [self.currentOrder.linkType isEqualToString:LinkType_Agora] && ([[AgoraManger sharedInstance] isConnected] == NO)) {
            [[AgoraManger sharedInstance] callWithRoomID:self.currentOrder.flowId];
            // 加入房间建立连接后  声网回调里面会掉用callDidconnected
        }else{
              [[TransnSDK   shareManger] printLog:[NSString stringWithFormat:@"再次收到译员信息 语音单:%@，语音通话是否连接:%@",self.currentOrder.linkType,@([[AgoraManger sharedInstance] isConnected])]];
        }
    }
}

#pragma mark  通知服务器挂断电话

/**
 *   //挂断原因类型：
 *   // 0-用户取消
 *   // 1-用户端正常挂断
 *   // 2-译员端正常挂断
 *   // 3-服务端感知译员掉线挂断
 *   // 4-用户端感知译员端掉线挂断
 *   // 5-译员端感知用户端掉线挂断
 *   // 6-TBox挂断电话
 */

- (void)httpServerHangUp:(TRNetCallDisconnectReason)type
{
    static NSString *islock = @"0";
    
    @synchronized(islock) {
        if (self.currentOrder.isConnected || (type == TRUserCancle)) {// 0是取消操作，通话不一定建立了
            self.currentOrder.disconnectReason = type;
            self.currentOrder.isConnected = NO;
            [self stopSendHeartBreak];
            [self hangupVoiceCall];
            //服务器感知译员掉线，会直接掐断这个订单，不需要再去调用接口
            if (([self.currentOrder.flowId length] > 0) && (type != TRServerSensorTransIMOffLine)) {
                NSString *finishReasonType = @"";
                switch (type) {
                    case TRUserCancle:
                        finishReasonType = @"UserCancle";
                        break;
                        
                    case TRUserComplete:
                        finishReasonType = @"UserComplete";
                        break;
                        
                    case TRTransComplete:
                        finishReasonType = @"TransComplete";
                        break;
                        
                    case TRServerSensorTransIMOffLine:
                        finishReasonType = @"ServerSensorTransIMOffLine";
                        break;
                        
                    case TRUserSensorTransOffLine:
                        finishReasonType = @"UserSensorTransOffLine";
                        break;
                        
                    case TRTransSensorUserOffLine:
                        finishReasonType = @"TransSensorUserOffLine";
                        break;
                        
                    case TRUserIMOffLine:
                        finishReasonType = @"UserIMOffLine";
                        break;
                        
                    case TRTransIMOffLine:
                        finishReasonType = @"TransIMOffLine";
                        break;
                        
                    case TRTransAppKill:
                        finishReasonType = @"TransAppKill";
                        break;
                        
                    case TRTransnBox_RingOff:
                        finishReasonType = @"TransnBox_RingOff";
                        break;
                        
                    default:
                        break;
                }
                NSDictionary *dic = TRDicWithOAndK(self.currentOrder.flowId, @"flowId", finishReasonType, @"finishReasonType");
                [[TRNetWork sharedManager] requestURLPath:ST_API_finishCall httpMethod:TRRequestMethodPost parmas:dic completetion:^(id responseObject, NSError *error) {
                    if (self.delegate && [self.delegate respondsToSelector:@selector(netCallStatusDisconnectWithType:orderInfo:)]) {
                        [self.delegate netCallStatusDisconnectWithType:type orderInfo:responseObject];
                    }
                    
                    TRBaseModel *model = [[TRBaseModel alloc] initWithDictionary:responseObject];
                    
                    if (model.isStatusOK) {
                        [[TransnSDK shareManger] printLog:@"挂断成功"];
                    } else {
                        [[TransnSDK shareManger] printLog:@"挂断失败"];
                    }
                }];
            } else {
                if (self.delegate && [self.delegate respondsToSelector:@selector(netCallStatusDisconnectWithType:orderInfo:)]) {
                    [self.delegate netCallStatusDisconnectWithType:type orderInfo:nil];
                }
            }
        } else {
            [[TransnSDK shareManger] printLog:@"_isConnected 没有连接，不调用挂断接口"];
        }
    }
}

#pragma mark - 通话相关方法

#pragma mark - 获取译员信息


- (void)hangupCallWithFlowId:(NSString *)flowId
{
    if (self.currentOrder==nil) {
        [self startFlow:flowId linkType:@"chat"];
    }else{
        self.currentOrder.flowId = flowId;
    }
    [self hangupCurrentCall];
}

- (void)hangupCurrentCall
{
    [[TransnSDK shareManger] printLog:@"调用挂断方法"];
    translatorId = nil;
    NSError *aError = [[TransnSDK shareManger] checkAppIDAndAppSecretAvaliable];
    
    if (aError) {
        return;
    }
    
 
    
    if (self.currentOrder.isConnected == NO) {
        [self sendUserCancleOrderTip];
        [self httpServerHangUp:TRUserCancle];// 取消
    } else {
        if (([self.currentOrder.flowId length] > 0) && ([self.currentOrder.translator.translatorId length] > 0)) {
            [self sendHungUpTip];
        }
        
        [self httpServerHangUp:TRUserComplete];// 自己主动挂断电话
    }
}

#pragma mark - 对外接口

- (void)setSpeaker:(BOOL)isSpeakerOn
{
    NSError *aError = [[TransnSDK shareManger] checkAppIDAndAppSecretAvaliable];
    
    if (aError) {
        return;
    }
    
    if (self.currentOrder.isAgoraVoiceLine) {
        [[AgoraManger sharedInstance] setSpeaker:isSpeakerOn];
    } else {
        //        [[TwilioManager sharedInstance] setSpeaker:isSpeakerOn];
    }
}

- (void)setMute:(BOOL)isMute
{
    NSError *aError = [[TransnSDK shareManger] checkAppIDAndAppSecretAvaliable];
    
    if (aError) {
        return;
    }
    
    if (self.currentOrder.isAgoraVoiceLine) {
        [[AgoraManger sharedInstance] setMute:isMute];
    } else {
        //        [[TwilioManager sharedInstance] setMute:isMute];
    }
}

- (int)setDefaultAudioRouteToSpeakerphone:(BOOL)defaultToSpeaker{
    return [[AgoraManger sharedInstance] setDefaultAudioRouteToSpeakerphone:defaultToSpeaker];
}

//- (void)setSpeakerphoneVolume:(NSUInteger)volume{
//    NSError *aError = [[TransnSDK shareManger] checkAppIDAndAppSecretAvaliable];
//    
//    if (aError) {
//        return;
//    }
//    
//    if (self.currentOrder.isAgoraVoiceLine) {
//        [[AgoraManger sharedInstance] setSpeakerphoneVolume:volume];
//    } else {
//        //        [[TwilioManager sharedInstance] setSpeaker:isSpeakerOn];
//    }
//}


///**
// *  Enables to report to the application about the volume of the speakers.
// *
// *  @param interval Specifies the time interval between two consecutive volume indications.
// <=0: Disables volume indication.
// >0 : The volume indication interval in milliseconds. Recommandation: >=200ms.
// *  @param smooth   The smoothing factor. Recommended: 3.
// *
// */
//- (void)enableAudioVolumeIndication:(NSInteger)interval
//                             smooth:(NSInteger)smooth{
//    [[AgoraManger sharedInstance] enableAudioVolumeIndication:interval smooth:smooth];
//}
/**
 指定本地音频文件来和麦克风采集的音频流进行混音和替换(用音频文件替换麦克风采集的音频流)， 可以通过参数选择是否让对方听到本地播放的音频和指定循环播放的次数。该 API 也支持播放在线音乐。
 
 @param filePath 指定需要混音的本地音频文件名和文件路径名:
 支持以下音频格式: mp3, aac, m4a, 3gp, wav, flac
 @param loopback True: 只有本地可以听到混音或替换后的音频流  False: 本地和对方都可以听到混音或替换后的音频流
 @param replace True: 音频文件内容将会替换本地录音的音频流  False: 音频文件内容将会和麦克风采集的音频流进行混音
 @param cycle 指定音频文件循环播放的次数: 正整数: 循环的次数 -1: 无限循环
 @return 0: 方法调用成功 <0: 方法调用失败
 */
- (int)startAudioMixing:(NSString*) filePath
               loopback:(BOOL) loopback
                replace:(BOOL) replace
                  cycle:(NSInteger) cycle
                  didFinish:(void (^)(void))didFinish{
    if (self.currentOrder.isAgoraVoiceLine) {
      return [[AgoraManger sharedInstance] startAudioMixing:filePath loopback:loopback replace:replace cycle:cycle didFinish:didFinish];
    } else {
        return -1;
    }
}
//
//
/**
 停止播放伴奏 (stopAudioMixing)
 
 @return 0：方法调用成功 <0: 方法调用失败
 */
- (int)stopAudioMixing{
    if (self.currentOrder.isAgoraVoiceLine) {
        return  [[AgoraManger sharedInstance] stopAudioMixing];
    } else {
        return -1;
    }
}
//
//
///**
// 暂停播放伴奏 (pauseAudioMixing)
// 
// @return 0：方法调用成功 <0: 方法调用失败
// */
//- (int)pauseAudioMixing{
//    if (self.currentOrder.isAgoraVoiceLine) {
//        return  [[AgoraManger sharedInstance] pauseAudioMixing];
//    } else {
//        return -1;
//    }
//}
//
//
///**
// 恢复播放伴奏 (resumeAudioMixing)
// 
// @return 0：方法调用成功 <0: 方法调用失败
// */
//- (int)resumeAudioMixing{
//    if (self.currentOrder.isAgoraVoiceLine) {
//        return  [[AgoraManger sharedInstance] resumeAudioMixing];
//    } else {
//        return -1;
//    }
//}
//
//
///**
// 调节伴奏音量 (adjustAudioMixingVolume)
// 
// @param volume 伴奏音量范围为 0~100。默认 100 为原始文件音量
// @return 0：方法调用成功 <0: 方法调用失败
// */
//- (int)adjustAudioMixingVolume:(NSInteger) volume{
//    if (self.currentOrder.isAgoraVoiceLine) {
//        return  [[AgoraManger sharedInstance] adjustAudioMixingVolume:volume];
//    } else {
//        return -1;
//    }
//}
//
//
///**
// 该方法获取伴奏时长，单位为毫秒。请在频道内调用该方法。
// 
// @return 0：方法调用成功 <0: 方法调用失败
// */
//- (int)getAudioMixingDuration{
//    if (self.currentOrder.isAgoraVoiceLine) {
//        return  [[AgoraManger sharedInstance] getAudioMixingDuration];
//    } else {
//        return -1;
//    }
//}
//
//
///**
// 获取伴奏播放进度 (getAudioMixingCurrentPosition)
// 
// @return 0：方法调用成功 <0: 方法调用失败
// */
//- (int)getAudioMixingCurrentPosition{
//    if (self.currentOrder.isAgoraVoiceLine) {
//        return  [[AgoraManger sharedInstance] getAudioMixingCurrentPosition];
//    } else {
//        return -1;
//    }
//}
//
//
///**
// 拖动语音进度条 (setAudioMixingPosition)
// 
// @param pos 整数。进度条位置，单位为毫秒
// @return 0：方法调用成功 <0: 方法调用失败
// */
//- (int)setAudioMixingPosition:(NSInteger) pos{
//    if (self.currentOrder.isAgoraVoiceLine) {
//        return  [[AgoraManger sharedInstance] setAudioMixingPosition:pos];
//    } else {
//        return -1;
//    }
//}
/**
 *  与译员进行语音通话
 */
- (int)contectTranslatorWithVoice
{
    return [self.currentOrder contectTranslatorWithVoice];
 }

- (int)disContectTranslatorWithVoice
{
    return [self.currentOrder disContectTranslatorWithVoice];
}

-(BOOL)canSwitchVoice{
    return self.currentOrder.canSwitchVoice;
}


- (BOOL)isContectTranslatorWithVoice
{
    return self.currentOrder.isContectTranslatorWithVoice;
}

#pragma mark 检测敏感词
// 检测敏感词 超时、失败、无数据不返回结果，有敏感词则返回msg对象---只对textmessage检测
- (void)checkSensitiveWords:(TRMessage *)msg completion:(void (^)(void))completionBlock
{
    if ((msg == nil) || (msg.content == nil) || (msg.content.length == 0)) {
        if (completionBlock) {
            completionBlock();
        }
        return;
    }
    
    NSMutableString *readyToCheckString = [[NSMutableString alloc] init];
    
    if (msg.messageType == TIMMessageTypeText) {
        [readyToCheckString appendString:msg.content];
    } else {
        switch (msg.paymentMessageType) {
            case PaymentMsgTypeText2Voice:
                [readyToCheckString appendString:[NSString stringWithFormat:@"%@", msg.content]];
                break;
                
            case PaymentMsgTypeText2Text:
                [readyToCheckString appendString:[NSString stringWithFormat:@"%@  ", msg.content]];
                [readyToCheckString appendString:[NSString stringWithFormat:@"%@", msg.translateContent]];
                break;
                
            case PaymentMsgTypeVoice2Text:
                [readyToCheckString appendString:[NSString stringWithFormat:@"%@", msg.translateContent]];
                break;
                
            case PaymentMsgTypeImage2Text:
                [readyToCheckString appendString:[NSString stringWithFormat:@"%@", msg.translateContent]];
                break;
                
            default:
                break;
        }
    }
    
    NSDictionary *dic = TRDicWithOAndK(readyToCheckString, @"contents", msg.messageID, @"messageId");
    [[TRNetWork sharedManager] requestURLPath:ST_API_sensitivewords_checkSensitiveWords httpMethod:TRRequestMethodPost parmas:dic completetion:^(id responseObject, NSError *error) {
        if (completionBlock) {
            completionBlock();
        }
        
        if (error) {} else {
            TRBaseModel *model = [[TRBaseModel alloc] initWithDictionary:responseObject];
            
            if ([model.result isEqualToString:@"1"]) {
                NSArray *sensitiveWordsList = model.data[@"sensitiveWordsList"];
                
                if (sensitiveWordsList && sensitiveWordsList.count) {
                    //有敏感词
                    if (self.delegate && [self.delegate respondsToSelector:@selector(onRecvSensitiveWordsMessage:)]) {
                        msg.sensitiveWords = sensitiveWordsList;
                        [self.delegate onRecvSensitiveWordsMessage:msg];
                    }
                }
            }
        }
    }];
}

- (void)evaluateOrder:(NSString *)flowId comment:(NSString *)comment star:(int)star completetion:(TIMCompletionBlock)completion
{
    NSDictionary *dic = TRDicWithOAndK(flowId, @"flowId", comment, @"comment", @(star), @"star");
    
    [[TRNetWork sharedManager] requestURLPath:ST_API_conversation_setScoreStar httpMethod:TRRequestMethodPost parmas:dic completetion:completion];
}

- (void)addThirdPartPhone:(NSString *)phone room:(NSString *)room completetion:(TIMCompletionBlock)completion
{
    NSDictionary *dic = TRDicWithOAndK(phone, @"dynamicJoin", room, @"room");
    
    [[TRNetWork sharedManager] requestURLPath:ST_API_twilio_callAndDynamicJoinConference httpMethod:TRRequestMethodPost parmas:dic completetion:completion];
}

@end
