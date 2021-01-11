//
//  TransnSDK+Private.h
//  TransnSDK
//
//  Created by Fan Lv on 16/10/27.
//  Copyright © 2016年 Transn. All rights reserved.
//

#import "TransnSDK.h"
#import "TRFileLog.h"


typedef NS_ENUM (NSInteger, OnlineState) {
    OnlineStateOffLine = 0, // 离线
    OnlineStateOnLine = 1,  // 在线
    OnlineStateBusy = 2,    // 忙碌
};

static NSString *const  HangUpTip = @"IHungUpTheCall";
static NSString *const  ResponseCallError = @"BuilldCallLineError";
static NSString *const  CallingUserTip = @"TranserIsCallingTheUser";            //;// TRAPIDeprecated("TransaltorAcceptedOrder");
static NSString *const  TransnerInfo = @"TransnerInfoJsonStr:";                 // 老版本
static NSString *const  TransaltorAcceptedOrder = @"TransaltorAcceptedOrder:";  // 6.1收到译员接单+译员信息

static NSString *const  CustomJsonStr = @"CustomJsonStr:";
static NSString *const  UserCancelTheOrder = @"UserCancelTheOrder";
static NSString *const  UserUseVoiceCallingTranslator = @"UserUseVoiceCallingTranslator";
static NSString *const  UserExitVoice = @"UserExitAgora";
static NSString *const  UserConfirmTheOrder = @"UserConfirmTheOrder";             // 6.3发送用户确认订单

static NSString *const  Iam30sTimeOut = @"Iam30sTimeOut";
static NSString *const  IkillTheApp = @"IkillTheApp";
static NSString *const  isSupportVoice = @"isSupportVoice";
static NSString *const  IolHeartBreak = @"IolHeartBreak";                   //  7.1发送\接收心跳
static NSString *const  BaiduPreCharge = @"baiduPreCharge:";                // 百度预付费需求，译员开始翻译
static NSString *const  BalanceCheckResult = @"balanceCheckResult:";        // 百度预付费需求，是否译员翻译



@interface TransnSDK (Private)


@property (nonatomic, copy) NSString *countryId;

@property (nonatomic, copy) NSString    *twiiloToken;
@property (nonatomic, copy) NSString    *qiNiuUploadImageUrl;

@property (nonatomic, copy) NSString    *qiNiuToken;
@property (nonatomic, copy) NSString    *qiNiuBaseUrl;

@property (nonatomic, strong) NSDate *timeToGetQiNiuToken;

@property (nonatomic, strong) NSNumber *serverUtcTimestampDvalue;

@property (nonatomic, copy) NSString *userIP;

@property (nonatomic, copy) NSString *coreServerIp;

@property (nonatomic, copy) NSString *clientID;

@property (nonatomic, strong) NSNumber *xmppAutoLoginOutTime;  // 默认15分钟之后，未呼单，就退出XMPP，账号不退出，下次呼叫，自动登录XMPP

@property (nonatomic, assign) BOOL   isLoginSDK;

- (void)uploadData:(NSData *)data fileName:(NSString *)fileName withExtention:(NSString *)ext completionHandler:(void (^)(NSString *fileUrl, NSError *error))completionHandler;

- (OnlineState)myOnlineState;

- (void)setMyOnlineState:(OnlineState)myOnlineState;

- (NSError *)checkAppIDAndAppSecretAvaliable;

- (void)printLog:(NSString *)toast;

- (void)printMessageLog:(NSString *)toast;

- (void)writeToast:(NSString *)toast;

- (void)uploadErrorLog:(NSString *)expTitle expMsg:(NSString *)expContent;

- (void)uploadErrorLog:(NSString *)expTitle expMsg:(NSString *)expContent flowId:(NSString *)flowId;

- (NSString *)appSEVER_IP_CORE_CN:(TransnEnvironment)defaultMode;



- (void)getMyIPCountry;

- (void)getTwilioToken:(void (^)(NSError *error))completion;

- (NSString *)getBuildVersion;
@end
