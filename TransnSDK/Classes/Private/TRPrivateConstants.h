//
//  TRPrivateConstants.h
//  TransnSDK
//
//  Created by 姜政 on 2017/8/17.
//  Copyright © 2017年 Transn. All rights reserved.
//

#ifndef TRPrivateConstants_h
#define TRPrivateConstants_h
#import "TransnSDK.h"
#define POST                                            @"POST"
#define GET                                             @"GET"


#define SEVER_IP_Core_Product                           @"https://core.itakeeasy.com/"  // 正式

#define SEVER_IP_Core_Development                       @"http://test-core.itakeeasy.cn/"    // 18
//#define SEVER_IP_Core_Development                       @"https://core.iolapi.com/"   //195
#define SEVER_IP_Core_Test                              @"http://core.itakeeasy.net/"   // 19




#define SEVER_IP_Core                                   [TransnSDK shareManger].coreServerIp


static NSString *const  LinkType_Twilio = @"twilio";
static NSString *const  LinkType_Agora = @"agora";
static NSString *const  LinkType_Tencent = @"tencent";
static NSString *const  LinkType_TextWithTwilio = @"ChatWithTwilio";
static NSString *const  LinkType_TextWithAgora = @"ChatWithAgora";
static NSString *const  LinkType_TransnBox = @"TransnBox";


// 获取明星译员
#define  ST_API_conversation_translatorRecommendation   [SEVER_IP_Core stringByAppendingString:@"conversation/translatorRecommendation"]

// #pragma mark 2.0.0 2017-11-09 姜政修改
#define  ST_API_twilio_callAndDynamicJoinConference     [SEVER_IP_Core stringByAppendingString:@"twilio/callAndDynamicJoinConference2"]

#define  ST_API_conversation_setScoreStar               [SEVER_IP_Core stringByAppendingString:@"conversation/setScoreStar"]
#define ST_API_conversation_heartbeat                   [SEVER_IP_Core stringByAppendingString:@"conversation/heartbeat"]

#define ST_API_twilio_getTwilioToken                    [SEVER_IP_Core stringByAppendingString:@"twilio/getTwilioToken"]

#define ST_API_conversation_call                        [SEVER_IP_Core stringByAppendingString:@"conversation/call"]
///保存聊天记录
#define ST_API_saveChatHistory                          [SEVER_IP_Core stringByAppendingString:@"conversation/saveChatHistory"]

#define ST_API_uploadException                          [SEVER_IP_Core stringByAppendingString:@"app/server/exception"]

#define ST_API_getTranslatorByFlowId                    [SEVER_IP_Core stringByAppendingString:@"conversation/getTranslatorByFlowId"]

#define ST_API_conversationStart                        [SEVER_IP_Core stringByAppendingString:@"conversation/start"]

#define ST_API_conversation_switchCallMode              [SEVER_IP_Core stringByAppendingString:@"conversation/switchCallMode"]

// 检测敏感词
#define ST_API_sensitivewords_checkSensitiveWords       [SEVER_IP_Core stringByAppendingString:@"sensitivewords/checkSensitiveWords"]

// 留言保活
#define ST_API_keepAliveByMsg                           [SEVER_IP_Core stringByAppendingString:@"conversation/keepAliveByMsg"]

// 用户领取
#define ST_API_userReceive                              [SEVER_IP_Core stringByAppendingString:@"conversation/userReceive"]

// 检查用户是否有未完成的留言订单
#define ST_API_checkUserCallBack                        [SEVER_IP_Core stringByAppendingString:@"conversation/checkUserCallBack"]

// 获取语种列表
#define ST_API_getLanguageList                          [SEVER_IP_Core stringByAppendingString:@"userResources/langList"]

///挂断电话
#define ST_API_finishCall                               [SEVER_IP_Core stringByAppendingString:@"conversation/finish"]

// 译员总体状态
#define ST_API_checkTranslatorNum                       [SEVER_IP_Core stringByAppendingString:@"conversation/checkTranslatorNum"]

// 获取译员状态
#define ST_API_conversation_searchTransnOnlineStatus    [SEVER_IP_Core stringByAppendingString:@"conversation/searchTransnOnlineStatus"]

#define ST_API_conversation_pullImLogUrlByFlowId        [SEVER_IP_Core stringByAppendingString:@"conversation/pullImLogUrlByFlowId"]

#define ST_API_conversation_sendAuthResult2Server [SEVER_IP_Core stringByAppendingString:@"conversation/sendAuthResult2Server"]

//获取文件ID
#define ST_API_file_upload                         [SEVER_IP_Core stringByAppendingString:@"file/upload"]

//获取文件报价
#define ST_API_morder_getQuote                           [SEVER_IP_Core stringByAppendingString:@"morder/getQuote"]

//预约单下单
#define ST_API_morder_create                         [SEVER_IP_Core stringByAppendingString:@"morder/create"]


//预约订单留言
#define ST_API_morder_createMessage                         [SEVER_IP_Core stringByAppendingString:@"morder/createMessage"]
#endif /* TRPrivateConstants_h */
