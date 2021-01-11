//
//  TROrder+Private.m
//  TransnSDK
//
//  Created by 姜政 on 2018/2/12.
//  Copyright © 2018年 Transn. All rights reserved.
//

#import "TROrder+Private.h"
#import "TRNetWork.h"
#import "TRBaseModel.h"
#import "TRPrivateConstants.h"
#import "TransnSDK+Private.h"


@implementation TROrder (Private)

- (BOOL)isAgoraVoiceLine
{
    BOOL b = [[self.linkType lowercaseString] containsString:[LinkType_Agora lowercaseString]];
    
    return b;
}

- (BOOL)isTwilioVoiceLine
{
    BOOL b = [[self.linkType lowercaseString] containsString:[LinkType_Twilio lowercaseString]];
    
    return b;
}

///语音连接上
-(void)voiceDidConnected{
    BOOL isSwitchingVoice = !self.canSwitchVoice;//不能切换，就是刚刚切换了语音
    if (([self.flowId length] > 0) && isSwitchingVoice  && self.isAgoraVoiceLine) {
        NSDictionary *dic = TRDicWithOAndK(@"1", @"conversationMode", [NSString stringWithFormat:@"%@", self.flowId], @"flowId");
        [[TRNetWork sharedManager] requestURLPath:ST_API_conversation_switchCallMode httpMethod:TRRequestMethodPost parmas:dic completetion:^(id responseObject, NSError *error) {
            TRBaseModel *model = [[TRBaseModel alloc] initWithDictionary:responseObject];
            
            if (model.isStatusOK) {
                [[TransnSDK shareManger] printLog:@"调用switchCallMode成功"];
            } else {
                [[TransnSDK shareManger] printLog:@"调用switchCallMode失败"];
            }
        }];
    }
}


///语音断开
- (void)voiceDidDisConnected{
      BOOL isSwitchingVoice = !self.canSwitchVoice;//不能切换，就是刚刚切换了语音
    if (([self.flowId length] > 0) && isSwitchingVoice && self.isTextOrder) {
        NSDictionary *dic = TRDicWithOAndK(@"0", @"conversationMode", [NSString stringWithFormat:@"%@", self.flowId], @"flowId");
        [[TRNetWork sharedManager] requestURLPath:ST_API_conversation_switchCallMode httpMethod:TRRequestMethodPost parmas:dic completetion:^(id responseObject, NSError *error) {
            TRBaseModel *model = [[TRBaseModel alloc] initWithDictionary:responseObject];
            if (model.isStatusOK) {
                [[TransnSDK shareManger] printLog:@"调用switchCallMode成功"];
            } else {
                [[TransnSDK shareManger] printLog:@"调用switchCallMode失败"];
            }
        }];
    }
}
@end
