/*!
 *   TROrder.m
 *   TransnSDK
 *
 *   Created by 姜政 on 2018/2/12
 *   Copyright © 2018年 Transn. All rights reserved.
 */

#import "TROrder.h"
#import "TransnSDK+Private.h"
#import "TROrder+Private.h"
#import "AgoraManger.h"
#import "TROrderManger+Private.h"



@interface TROrder(){
      BOOL    isSwitchingVoice;// 防止重复点击 连接语音
}
@end

@implementation TROrder

- (BOOL)isTextOrder
{
    BOOL b = [[self.linkType lowercaseString] containsString:@"chat"];
    
    return b;
}
-(instancetype)init{
    if (self = [super init]) {
        _orderTime = 0;
        _isConnected = NO;
    }
    return self;
}
-(void)setIsConnected:(BOOL)isConnected{
    _isConnected = isConnected;
    if (isConnected) {
        [TransnSDK shareManger].myOnlineState = OnlineStateBusy;
    }else{
       [TransnSDK shareManger].myOnlineState = OnlineStateOnLine;
    }
}
/*
**
*  与译员进行语音通话
*/
- (int)contectTranslatorWithVoice
{
    if (isSwitchingVoice) {
        TRLog(@"15秒内重复调用%s", __func__);
        return 9000;
    }
    
    isSwitchingVoice = YES;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self->isSwitchingVoice = NO;
    });
    if (self.isTextOrder) {
        [[TransnSDK shareManger].orderManger sendUserUseVoiceTip];
       return  [[AgoraManger sharedInstance] callWithRoomID:self.flowId];
    } else {
        // 在用户叫单的时候就初始化了Twillo SDK,所以这里不用做任何操作，等待译员呼叫过来就行。
        return 0;
    }
    
}

- (int)disContectTranslatorWithVoice
{
    if (isSwitchingVoice) {
        TRLog(@"15秒内重复调用%s", __func__);
        return 9000;
    }
    
    isSwitchingVoice = YES;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self->isSwitchingVoice = NO;
    });
    
    if (self.isAgoraVoiceLine) {
        [[TransnSDK shareManger].orderManger sendUserExitVoiceTip];
        return [[AgoraManger sharedInstance] hangUp];
    } else {
        return 0;
    }
}

-(BOOL)canSwitchVoice{
    return !isSwitchingVoice;
}


- (BOOL)isContectTranslatorWithVoice
{
    if (self.isAgoraVoiceLine) {
        return [[AgoraManger sharedInstance] isConnected];
    } else {
        return NO;
    }
}

@end
