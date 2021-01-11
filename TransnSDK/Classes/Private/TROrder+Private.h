//
//  TROrder+Private.h
//  TransnSDK
//
//  Created by 姜政 on 2018/2/12.
//  Copyright © 2018年 Transn. All rights reserved.
//

#import "TROrder.h"


@interface TROrder (Private)

@property (nonatomic,assign,readonly)BOOL   isAgoraVoiceLine;

@property (nonatomic,assign,readonly)BOOL   isTwilioVoiceLine;

///语音连接上
-(void)voiceDidConnected;


///语音断开
- (void)voiceDidDisConnected;
@end
