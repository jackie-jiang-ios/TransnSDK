//
//  TransnSDK.m
//  TransnSDK
//
//  Created by VanRo on 16/6/1.
//  Copyright © 2016年 Transn. All rights reserved.
//

#import "TransnSDK.h"
#import "TRBaseModel.h"
#import <AVFoundation/AVFoundation.h>

#import "XMPPManager.h"
#import "AgoraManger.h"

#import "TransnSDK+Private.h"
#import "TROrderManger+Private.h"

#import "TRLanguageFile.h"
#import "TRPrivateConstants.h"
#import "TRNetWork.h"
#import "NSObject+TRKeyValue.h"
//#import "CoreDataEnvirHeader.h"
#import <MagicalRecord/MagicalRecord.h>
#import "NSManagedObject+TExtension.h"
#import "TRReservationManager.h"
#import "TRError.h"
#import "TRTestCell.h"
#import "MagicalRecord+Transn.h"


@interface TransnSDK ()
{
        NSTimer     *_autoLoginOutTimer;                // 15分钟没呼单，就挂断socket
        NSInteger    _autoLoginOutTimerflag; // 15分钟没呼单，就挂断socket
        BOOL _isForceLoginOut;          //强制下线
  
}
@property (nonatomic, assign) TransnEnvironment   environment;


@end

@implementation TransnSDK

static TransnSDK *_chatManger = nil;
+ (TransnSDK *)shareManger
{
    static dispatch_once_t onceTransnIM;
    
    dispatch_once(&onceTransnIM, ^{
        _chatManger = [[TransnSDK alloc] init];
    });
    return _chatManger;
}


#pragma mark SDK 2.0.0 2017-11-08
- (void)setShowLog:(BOOL)showLog
{
    _showLog = showLog;
    [TRFileLog sharedManager].logEnabled = showLog;
}
-(void)setShowMoreLog:(BOOL)showMoreLog{
    _showMoreLog = showMoreLog;
    [TRFileLog sharedManager].logAllEnabled = showMoreLog;
}

+ (void)registerAppKey:(NSString *)appKey appSecret:(NSString *)appSecret environment:(TransnEnvironment)environment
{
    if (([appKey length] == 0) || ([appSecret length] == 0)) {
        TRLog(@"appID和appSecret不能为空");
        return;
    }
    [TRNetWork sharedManager].appKey = appKey;
    [TRNetWork sharedManager].appSecret = appSecret;
    ///重要，sdk中的coredata文件路径和普通的project是不一样的
//    [MagicalRecord setDefaultModelFromClass:[TRTestCell class]];
    [MagicalRecord setTransnDefaultModelFromClass:[TRTestCell class]];
    [MagicalRecord setupCoreDataStackWithStoreNamed:@"Transn.sqlite"];
    #ifdef DEBUG
        [MagicalRecord setLoggingLevel:MagicalRecordLoggingLevelAll];
    #else
        [MagicalRecord setLoggingLevel:MagicalRecordLoggingLevelOff];
    #endif
 
    
    [TransnSDK shareManger].environment = environment;
    [TransnSDK shareManger].coreServerIp = [[TransnSDK shareManger] appSEVER_IP_CORE_CN:environment];
    [[TransnSDK shareManger] getMyIPCountry];
    
}

#pragma mark - Propety
static TROrderManger *orderManger = nil;
- (TROrderManger *)orderManger
{
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        if (orderManger == nil) {
            orderManger = [[TROrderManger alloc] init];
            // 默认为NO
            orderManger.checkSendMsgSensitiveWords = NO;
            orderManger.checkRecvMsgSensitiveWords = NO;
        }
    });
    return orderManger;
}

-(TRReservationManager *)reservationManager{
    if (!_reservationManager) {
        _reservationManager = [[TRReservationManager alloc] init];
    }
    return _reservationManager;
}
- (BOOL)isLogined
{
    return [[XMPPManager sharedInstance].xmppStream isAuthenticated];
}
-(BOOL)isAuthenticated{
     return [[XMPPManager sharedInstance].xmppStream isAuthenticated];
}
- (NSString *)myUserID
{
    return [XMPPManager sharedInstance].myJID.user;
}

#pragma mark - Init

- (id)init
{
    self = [super init];
    
    if (self) {
        [self initBlocks];
        self.lowConsumption = YES;
        self.xmppAutoLoginOutTime = @(15*60);
        self.countryId = @"";
    }
    
    return self;
}

- (void)initBlocks
{
    __weak __typeof(self) weakSelf = self;
    
    [XMPPManager sharedInstance].accountOnKickOut = ^() {
        if (weakSelf.accountOnKickOut) {
            [weakSelf printLog:@"设备被挤下线"];
            weakSelf.accountOnKickOut();
        }
    };
 
}
-(void)setAutoLoginOutTime:(NSNumber *)autoLoginOutTime{
    if (autoLoginOutTime.integerValue<0) {
       _autoLoginOutTime = @0;
       self.xmppAutoLoginOutTime = @0;
    }else if (autoLoginOutTime.integerValue<15) {
       _autoLoginOutTime = autoLoginOutTime;
    }else{
        _autoLoginOutTime = @15;
    }
    self.xmppAutoLoginOutTime = _autoLoginOutTime;
}

#pragma mark - 对外 发送消息接口

+ (NSString *)getVersion;
{
    return @"3.0.18";
}

- (void)loginWithUserId:(NSString *)userId completetion:(void (^)(NSError *error))completion
{
 
    NSError *aError = [self checkAppIDAndAppSecretAvaliable];
    if (aError) {
        if (completion) {
            completion(aError);
        }
        
        return;
    }
    
    if (![userId isKindOfClass:[NSString class]]) {
        NSDictionary    *userInfo = [NSDictionary dictionaryWithObject:@"userId需要是字符串" forKey:NSLocalizedDescriptionKey];
        NSError         *aError = [NSError errorWithDomain:@"" code:60000 userInfo:userInfo];
        
        if (completion) {
            completion(aError);
        }
    } else if ([userId length] == 0) {
        NSDictionary    *userInfo = [NSDictionary dictionaryWithObject:@"userId不能为空" forKey:NSLocalizedDescriptionKey];
        NSError         *aError = [NSError errorWithDomain:@"" code:60001 userInfo:userInfo];
        
        if (completion) {
            completion(aError);
        }
    }else if(self.isLoginSDK){
        [self printLog:@"重复登录"];
        if ([userId isEqualToString:self.clientID]) {
            [self waitForLoginTime:30 completion:completion];
        }else{
            NSDictionary    *userInfo = [NSDictionary dictionaryWithObject:@"重复登录" forKey:NSLocalizedDescriptionKey];
            NSError         *aError = [NSError errorWithDomain:@"" code:60002 userInfo:userInfo];
            
            if (completion) {
                completion(aError);
            }
        }
    } else {
        if (!self.orderManger) {
            // 初始化
        }
        self.clientID = userId;
       [self printLog:@"调用登录"];
        self.isLoginSDK = YES;
        self.coreServerIp = [[TransnSDK shareManger] appSEVER_IP_CORE_CN:self.environment];
        [self getTwilioToken:^(NSError *error) {
            if (error) {
                completion(error);
            }else{
                [XMPPManager sharedInstance].accountDidAvilable = ^{
                    ///这个可能多次返回
                    if (completion) {
                        completion(nil);
                    }
                };
            }
        }];
        _isForceLoginOut = NO;
        if (self.lowConsumption&&self.xmppAutoLoginOutTime.integerValue) {
            // 开始执行新线程的Run Loop
            [_autoLoginOutTimer invalidate];
            _autoLoginOutTimer = nil;
            _autoLoginOutTimerflag = 0;
            _autoLoginOutTimer = [NSTimer scheduledTimerWithTimeInterval:60
                target                                                      :self
                selector                                                    :@selector(checkOrderTick:)
                userInfo                                                    :@"start"
                repeats                                                     :YES];
            [_autoLoginOutTimer fire];
            [[NSRunLoop currentRunLoop] addTimer:_autoLoginOutTimer forMode:NSRunLoopCommonModes];
        }
    }
}

-(void)waitForLoginTime:(int)time completion:(void (^)(NSError *error))completion{
    if (time>0) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (self.isLogined) {
                if (completion) {
                    completion(nil);
                }
            }else{
                [self waitForLoginTime:time-1 completion:completion];
            }
        });
    }else{
        NSDictionary    *userInfo = [NSDictionary dictionaryWithObject:@"重复登录" forKey:NSLocalizedDescriptionKey];
        NSError         *aError = [NSError errorWithDomain:@"" code:60002 userInfo:userInfo];
        if (completion) {
            completion(aError);
        }
    }
}
- (void)checkOrderTick:(NSTimer *)theTimer
{
    if (_autoLoginOutTimerflag>=self.xmppAutoLoginOutTime.integerValue) {
        [self unUsedloginOut];
        _isForceLoginOut = YES;
        [theTimer invalidate];
        theTimer = nil;
    }else{
        if (self.orderManger.currentOrder.isConnected) {
            //正在呼单
            _autoLoginOutTimerflag = 0;
        }else{
            //没有呼单就加1
            _autoLoginOutTimerflag++;
        }
    }
}
//没通话的时候，自动挂断
- (void)unUsedloginOut
{
    if (self.xmppAutoLoginOutTime) {
        if (!self.orderManger.currentOrder.isConnected) {
            [self loginOut:^(NSError *error) {
                
            }];
            //还原
             self.isLoginSDK = YES;
        }
    }
}

- (void)requestTranslator:(NSString *)sourceLangId destLangId:(NSString *)destLangId completetion:(TIMCompletionBlock)completion
{
    NSDictionary *dict = TRDicWithOAndK(sourceLangId, @"sourceLanguageId", destLangId, @"targetLanguageId");
    
    [[TRNetWork sharedManager] requestURLPath:ST_API_checkTranslatorNum httpMethod:TRRequestMethodPost parmas:dict completetion:completion];
}

- (void)getLanguageList:(void (^)(NSArray *langList))completion
{

    [[TRNetWork sharedManager] requestURLPath:ST_API_getLanguageList httpMethod:TRRequestMethodPost parmas:nil completetion:^(id responseObject, NSError *error) {
        if (error) {
            NSArray *LanguageList = [[NSUserDefaults standardUserDefaults] objectForKey:@"LanguageList"];
            
            if (LanguageList) {
                if (completion) {
                    completion(LanguageList);
                }
            } else {
                if (completion) {
                    completion(@[]);
                }
            }
        } else {
            NSArray *LanguageList = responseObject[@"data"][@"list"];
            
            if (LanguageList) {
                [[NSUserDefaults standardUserDefaults] setObject:LanguageList forKey:@"LanguageList"];
                
                if (completion) {
                    completion(LanguageList);
                }
            } else {
                if (completion) {
                    completion(@[]);
                }
            }
        }
    }];
}

- (void)loginOut:(void (^)(NSError *error))completion
{
    [[TransnSDK shareManger] printLog:@"退出登录"];
    if (self.isLoginSDK) {
        self.isLoginSDK = NO;
        NSError *aError = [self checkAppIDAndAppSecretAvaliable];
        
        if (aError) {
            if (completion) {
                completion(aError);
            }
        } else {
            //正在呼单，就挂断
            if (self.orderManger.currentOrder.isConnected) {
                [self.orderManger hangupCurrentCall];
            }
            [[XMPPManager sharedInstance] logOut];
            
            if (completion) {
                completion(nil);
            }
        }
    }else{
        if (completion) {
            completion(nil);
        }
    }
  
}

// 新版本查询消息接口
- (void)selectMessagesByFlowId:(NSString *)flowId result:(void (^)(NSArray <TRMessage *> *messages))block
{
    [TRMessageManagedObject selectMessagesByFlowId:flowId result:block];
}

// 新版本查询消息接口
- (void)selectMessagesByUserId:(NSString *)userId result:(void (^)(NSArray <TRMessage *> *messages))block
{
    if (self.orderManger.currentOrder.translator.translatorId) {
        [self selectMessagesByUserId:userId translatorId:self.orderManger.currentOrder.translator.translatorId result:block];
    } else {
        if (block) {
            block(@[]);
        }
    }
}

// 新版本查询消息接口
- (void)selectMessagesByTranslatorId:(NSString *)translatorId result:(void (^)(NSArray <TRMessage *> *messages))block
{
    if (self.clientID) {
        [self selectMessagesByUserId:self.clientID translatorId:translatorId result:block];
    } else {
        if (block) {
            block(@[]);
        }
    }
}

- (void)selectMessagesByUserId:(NSString *)userId translatorId:(NSString *)translatorId result:(void (^)(NSArray <TRMessage *> *messages))block
{
    [TRMessageManagedObject selectMessagesByUserId:userId translatorId:translatorId result:block];
}

- (void)getTransnCloudMesssagesByFlowId:(NSString *)flowId result:(void (^)(NSArray <TRMessage *> *messages, TRTranslator *translator, NSString *userId))block
{
    NSDictionary *dict = TRDicWithOAndK(flowId, @"flowId");
    
    [[TRNetWork sharedManager] requestURLPath:ST_API_conversation_pullImLogUrlByFlowId httpMethod:TRRequestMethodPost parmas:dict completetion:^(id responseObject, NSError *error) {
        TRBaseModel *model = [[TRBaseModel alloc] initWithDictionary:responseObject];
        
        if (model.isStatusOK) {
            NSString *downloadUrl = model.data[@"downloadUrl"];
            [[TRNetWork sharedManager] downLoadFile:downloadUrl completetion:^(NSString *filePath, NSError *error) {
                if (error) {
                    if (block) {
                        block(@[], nil, nil);
                    }
                } else {
                    NSError *error;
                    NSMutableString *tr_jsonString = [[NSMutableString alloc] initWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&error];
                    
                    if (error) {
                        if (block) {
                            block(@[], nil, nil);
                        }
                        
                        return;
                    }
                    NSMutableDictionary *fileDict =  [NSMutableDictionary dictionaryWithDictionary:[tr_jsonString tr_JSONObject]];
                    TRTranslator *translator = [[TRTranslator alloc] init];
                    [translator setValuesForKeysWithDictionary:fileDict];
                    NSString *userId = fileDict[@"clientUserId"];
                    NSArray *imNodeList = fileDict[@"imNodeList"];
                    NSMutableArray <TRMessage *> *TRMessages = [[NSMutableArray alloc] initWithCapacity:imNodeList.count];
                    
                    for (NSInteger i = 0; i < imNodeList.count; i++) {
                        NSDictionary *msgDic = [imNodeList objectAtIndex:i];
                        XMPPMessage *xmppMsg = [[XMPPManager sharedInstance] cloudXmppMessage:msgDic[@"body"] subject:msgDic[@"subject"] from:msgDic[@"fromId"] toId:msgDic[@"toId"] flowId:flowId messageID:msgDic[@"messageId"]];
                        
                        TRMessage *message = [[TRMessage alloc] initWithMessage:xmppMsg];
                        message.translatorMb = translator;
                        message.sendState = TIMMessageSendStateSuccess;
                        
                        if ([NSString stringWithFormat:@"%@", msgDic[@"creatTime"]].length == 13) {
                            long long createTime = [msgDic[@"creatTime"] longLongValue];
                            message.timestamp = [[NSDate alloc] initWithTimeIntervalSince1970:createTime / 1000];
                        } else {
                            long long createTime = [msgDic[@"creatTime"] longLongValue];
                            message.timestamp = [[NSDate alloc] initWithTimeIntervalSince1970:createTime];
                        }
//                        [TRMessageManagedObject updateMessage:message state:message.sendState  time:1 flowId:flowId userId:userId];
                        [TRMessages addObject:message];
                    }
                    
                    if (block) {
                        block(TRMessages, translator, userId);
                    }
                }
            }];
        } else {
            if (block) {
                block(@[], nil, nil);
            }
        }
    }];
}

- (NSArray *)getMessageHistoryWithJID:(NSString *)userID
{
    return [[XMPPManager sharedInstance] getMessageHistoryWithJID:userID];
}

- (void)deleteMessageHistoryWithJID:(NSString *)userID
{
    [[XMPPManager sharedInstance] deleteMessageHistoryWithJID:userID];
}

- (void)callTransnBoxWithFlowId:(NSString *)flowId
{
    [self.orderManger callTransnBoxWithFlowId:flowId];
}

#pragma mark  调HTTP接口请求服务器通知译员来Call我。

- (void)callTheServer:(NSDictionary *)dic completetion:(TIMCompletionBlock)completion
{
    [[TransnSDK shareManger] printLog:@"开始请求译员"];
    //    "flowId":"xxxxxx",//生成的订单ID
    //    "linkType":"twilio",//链路类型 twilio(twilio) 或者 nim(网易云信)
    //    "code":"300000",//呼叫结果
    //    "msg":"Assigned"//结果对应的信息
    
    //    300000：Assigned  //已经开始分配
    //    300001：Busy      //所有译员忙碌
    //    300002：NoMatch   //没有匹配到符合的译员
    [self checkIsCallEnable:^(id result, NSError *error) {
        if (error) {
            completion(result,error);
        }else{
            if (self.orderManger.currentOrder.isConnected) {
                [[TransnSDK shareManger] printLog:@"注意，上一单没正常结束"];
                [self.orderManger hangupCurrentCall];
            }
            [[TRNetWork sharedManager] requestURLPath:ST_API_conversation_call httpMethod:TRRequestMethodPost parmas:dic completetion:^(id responseObject, NSError *error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (error && completion) {
                        completion(nil, error);
                        return;
                    }

                    TRBaseModel *model = [[TRBaseModel alloc] initWithDictionary:responseObject];

                    if (model.isStatusOK) {
                        NSString* flowId = [model.data objectForKey:@"flowId"];
                        NSString *_linkType = [NSString stringWithFormat:@"%@", [model.data objectForKey:@"linkType"]];

                        if ([[model.data objectForKey:@"agoraAPPKey"] length]) {
                            NSString *agoraAPPKey = [NSString stringWithFormat:@"%@", [model.data objectForKey:@"agoraAPPKey"]];
                            [AgoraManger sharedInstance].agoraAPPKey = agoraAPPKey;
                        }

                        if ([[model.data objectForKey:@"agoraJoinChannelByKey"] length]) {
                            NSString *agoraJoinChannelByKey = [NSString stringWithFormat:@"%@", [model.data objectForKey:@"agoraJoinChannelByKey"]];
                            [AgoraManger sharedInstance].agoraJoinChannelByKey = agoraJoinChannelByKey;
                        }

                        if ([[model.data objectForKey:@"agoraRecordingServiceKey"] length]) {
                            NSString *agoraRecordingServiceKey = [NSString stringWithFormat:@"%@", [model.data objectForKey:@"agoraRecordingServiceKey"]];
                            [AgoraManger sharedInstance].agoraRecordingServiceKey = agoraRecordingServiceKey;
                        }

                        if ((_linkType.length > 0) && ![_linkType isEqualToString:@"<null>"]) {
                            [self.orderManger startFlow:flowId linkType:_linkType];
                        }

                        TRLog(@"_flowId : %@ , _linkType : %@", flowId, _linkType);

                        if ([[_linkType lowercaseString] containsString:@"twilio"]) {
                            //  [[TwilioManager sharedInstance] initWithCapabilityToken:_twiiloToken];
                        }

                        NSString *code = [NSString stringWithFormat:@"%@", [model.data objectForKey:@"code"]];
                        completion(TRDicWithOAndK(flowId, @"flowId", code, @"code", model.data[@"msg"], @"msg"), nil);
                    } else {
                        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:model.msg forKey:NSLocalizedDescriptionKey];
                        NSError *error = [NSError errorWithDomain:@"" code:60005 userInfo:userInfo];
                        completion(nil, error);
                    }
                });
            }];
        }
    }];
  
}
- (void)checkIsCallEnable:(TIMCompletionBlock)completion
{
    NSError *aError = [self checkAppIDAndAppSecretAvaliable];
    
    if (aError) {
        if (completion) {
            completion(nil, aError);
        }
        return;
    }
    if ([self isLogined]) {
        completion(@1,nil);
    }else{
        if (self.lowConsumption&&self.clientID&&_isForceLoginOut&&_autoLoginOutTimerflag==15) {
            [self loginWithUserId:self.clientID completetion:^(NSError *error) {
                if (error) {
                    completion(TRDicWithOAndK(@"", @"flowId", @"300002", @"code", @"NoMatch", @"msg"), nil);
                }else{
                     completion(@1,nil);
                }
            }];
        }else{
            completion(TRDicWithOAndK(@"", @"flowId", @"300002", @"code", @"NoMatch", @"msg"), nil);
        }
      
    }
}
- (void)checkUserCallBackWithCompletion:(TIMCompletionBlock)completion
{
    [[TRNetWork sharedManager] requestURLPath:ST_API_checkUserCallBack httpMethod:TRRequestMethodPost parmas:nil completetion:completion];
}

- (void)callTheServerSrcLangId  :(NSString *)srcLangId
        tarLangId               :(NSString *)tarLangId
        callerName              :(NSString *)callerName
        callerIcon              :(NSString *)callerIcon
        serviceType             :(int)serviceType
        lineType                :(int)lineType
        extraParams             :(NSDictionary *)extraParams
        completetion            :(TIMCompletionBlock)completion
{
    [self callTheServerSrcLangId:srcLangId
    tarLangId                   :tarLangId
    flowId                      :nil
    callerName                  :callerName
    callerIcon                  :callerIcon
    serviceType                 :serviceType
    lineType                    :lineType
    isWait                      :0
    extraParams                 :extraParams
    completetion                :completion];
}

- (void)callTheServerSrcLangId  :(NSString *)srcLangId
        tarLangId               :(NSString *)tarLangId
        flowId                  :(NSString *)flowId
        callerName              :(NSString *)callerName
        callerIcon              :(NSString *)callerIcon
        serviceType             :(int)serviceType
        lineType                :(int)lineType
        isWait                  :(int)isWait
        extraParams             :(NSDictionary *)extraParams
        completetion            :(TIMCompletionBlock)completion
{
    //    {
    //        "userId":"xxxxxx",//用户ID
    //        "appKey":"xxxxxx",//用户使用的APPKEY
    //        "countryId":"xxxxxx",//国家ID，通过init接口返回的ip来判断国家ID传给后台
    //        "translatorId":"xxxxxx",//直连使用的译员ID（可选）
    //        "sourceLanguageId":"1",//源语种ID
    //        "targetLanguageId":"2",//目标语种ID
    //        "udid":"xxxxxxx",//用户设备号
    //        "language":"zh_CN",//本地语言
    //        "serviceType":"1",//服务类型 // 1:（直链接// 2:(仅匹配兼职)// 3:(仅匹配专职)// 4:（匹配所有译员 先兼职10S后匹配专职）
    //        "isWait":"0",//是否等待 0不等待  1等待
    //        "extraParams":"" //业务方传递的额外参数，不做处理(包括用户昵称，头像等)
    //    }
    
    NSMutableDictionary *mParams;
    
    if (extraParams == nil) {
        mParams = [[NSMutableDictionary alloc] init];
    } else {
        mParams = [[NSMutableDictionary alloc] initWithDictionary:extraParams];
    }
    
    if ([callerName length] > 0) {
        [mParams setValue:callerName forKey:@"callerName"];
    }
    
    if ([callerIcon length] > 0) {
        [mParams setValue:callerIcon forKey:@"callerIcon"];
    }
    
    NSString *extraParamsStr = [mParams tr_JSONString];
    
    NSDictionary        *dic = TRDicWithOAndK([NSString stringWithFormat:@"%d", lineType], @"conversationMode", srcLangId, @"sourceLanguageId", tarLangId, @"targetLanguageId", [NSString stringWithFormat:@"%d", isWait], @"isWait", [NSString stringWithFormat:@"%d", serviceType], @"serviceType", extraParamsStr, @"extraParams", self.countryId, @"countryId");
    NSMutableDictionary *md = [NSMutableDictionary dictionaryWithDictionary:dic];
    
    if ([extraParams objectForKey:@"locationInfo"]) {
        [md setObject:[extraParams objectForKey:@"locationInfo"] forKey:@"locationInfo"];
    }
    
    if (flowId.length > 0) {
        [md setValue:flowId forKey:@"flowId"];
    }
    
    [self callTheServer:md completetion:completion];
}

- (void)callTheTranslator   :(NSString *)trId
        srcLangId           :(NSString *)srcLangId
        tarLangId           :(NSString *)tarLangId
        flowId              :(NSString *)flowId
        callerName          :(NSString *)callerName
        callerIcon          :(NSString *)callerIcon
        lineType            :(int)lineType
        extraParams         :(NSDictionary *)extraParams
        completetion        :(TIMCompletionBlock)completion
{
    NSMutableDictionary *mParams;
    
    if (extraParams == nil) {
        mParams = [[NSMutableDictionary alloc] init];
    } else {
        mParams = [[NSMutableDictionary alloc] initWithDictionary:extraParams];
    }
    
    if ([callerName length] > 0) {
        [mParams setValue:callerName forKey:@"callerName"];
    }
    
    if ([callerIcon length] > 0) {
        [mParams setValue:callerIcon forKey:@"callerIcon"];
    }
    
    NSString *extraParamsStr = [mParams tr_JSONString];
    
    NSDictionary *dic = TRDicWithOAndK([NSString stringWithFormat:@"%d", lineType], @"conversationMode",
                                       @"1", @"serviceType",
                                       self.countryId, @"countryId",
                                       trId, @"translatorId",
                                       extraParamsStr, @"extraParams");
    
    NSMutableDictionary *md = [NSMutableDictionary dictionaryWithDictionary:dic];
    
    if (flowId.length > 0) {
        [md setValue:flowId forKey:@"flowId"];
    }
    
    if ((srcLangId.length > 0) && ([srcLangId integerValue] > 0)) {
        [md setValue:srcLangId forKey:@"sourceLanguageId"];
    }
    
    if ((tarLangId.length > 0) && ([tarLangId integerValue] > 0)) {
        [md setValue:tarLangId forKey:@"targetLanguageId"];
    }
    
    if ([extraParams objectForKey:@"locationInfo"]) {
        [md setObject:[extraParams objectForKey:@"locationInfo"] forKey:@"locationInfo"];
    }
    
    [self callTheServer:md completetion:completion];
}

- (void)callTheTranslator   :(NSString *)trId
        srcLangId           :(NSString *)srcLangId
        tarLangId           :(NSString *)tarLangId
        flowId              :(NSString *)flowId
        callerName          :(NSString *)callerName
        callerIcon          :(NSString *)callerIcon
        userScore           :(NSString *)userScore
        judgeTransId        :(NSString *)judgeTransId
        lineType            :(int)lineType
        extraParams         :(NSDictionary *)extraParams
        completetion        :(TIMCompletionBlock)completion
{
    NSMutableDictionary *mParams;
    
    if (extraParams == nil) {
        mParams = [[NSMutableDictionary alloc] init];
    } else {
        mParams = [[NSMutableDictionary alloc] initWithDictionary:extraParams];
    }
    
    if ([callerName length] > 0) {
        [mParams setValue:callerName forKey:@"callerName"];
    }
    
    if ([callerIcon length] > 0) {
        [mParams setValue:callerIcon forKey:@"callerIcon"];
    }
    
    NSString *extraParamsStr = [mParams tr_JSONString];
    
    NSDictionary *dic = TRDicWithOAndK([NSString stringWithFormat:@"%d", lineType], @"conversationMode",
                                       @"1", @"serviceType",
                                       self.countryId, @"countryId",
                                       trId, @"translatorId",
                                       extraParamsStr, @"extraParams");
    
    NSMutableDictionary *md = [NSMutableDictionary dictionaryWithDictionary:dic];
    
    if (flowId.length > 0) {
        [md setValue:flowId forKey:@"flowId"];
    }
    
    if ((srcLangId.length > 0) && ([srcLangId integerValue] > 0)) {
        [md setValue:srcLangId forKey:@"sourceLanguageId"];
    }
    
    if ((tarLangId.length > 0) && ([tarLangId integerValue] > 0)) {
        [md setValue:tarLangId forKey:@"targetLanguageId"];
    }
    
    if (userScore.length > 0) {
        [md setValue:userScore forKey:@"userScore"];
    }
    
    if (judgeTransId.length > 0) {
        [md setValue:judgeTransId forKey:@"judgeTransId"];
    }
    
    if ([extraParams objectForKey:@"locationInfo"]) {
        [md setObject:[extraParams objectForKey:@"locationInfo"] forKey:@"locationInfo"];
    }
    
    [self callTheServer:md completetion:completion];
}

- (void)callTheServerSrcLangId  :(NSString *)srcLangId
        tarLangId               :(NSString *)tarLangId
        flowId                  :(NSString *)flowId
        callerName              :(NSString *)callerName
        callerIcon              :(NSString *)callerIcon
        userScore               :(NSString *)userScore
        judgeTransId            :(NSString *)judgeTransId
        serviceType             :(int)serviceType
        lineType                :(int)lineType
        isWait                  :(int)isWait
        extraParams             :(NSDictionary *)extraParams
        completetion            :(TIMCompletionBlock)completion
{
    NSMutableDictionary *mParams;
    
    if (extraParams == nil) {
        mParams = [[NSMutableDictionary alloc] init];
    } else {
        mParams = [[NSMutableDictionary alloc] initWithDictionary:extraParams];
    }
    
    if ([callerName length] > 0) {
        [mParams setValue:callerName forKey:@"callerName"];
    }
    
    if ([callerIcon length] > 0) {
        [mParams setValue:callerIcon forKey:@"callerIcon"];
    }
    
    NSString *extraParamsStr = [mParams tr_JSONString];
    
    NSDictionary        *dic = TRDicWithOAndK([NSString stringWithFormat:@"%d", lineType], @"conversationMode", srcLangId, @"sourceLanguageId", tarLangId, @"targetLanguageId", [NSString stringWithFormat:@"%d", isWait], @"isWait", [NSString stringWithFormat:@"%d", serviceType], @"serviceType", extraParamsStr, @"extraParams", self.countryId, @"countryId");
    NSMutableDictionary *md = [NSMutableDictionary dictionaryWithDictionary:dic];
    
    if (flowId.length > 0) {
        [md setValue:flowId forKey:@"flowId"];
    }
    
    if (userScore.length > 0) {
        [md setValue:userScore forKey:@"userScore"];
    }
    
    if (judgeTransId.length > 0) {
        [md setValue:judgeTransId forKey:@"judgeTransId"];
    }
    
    if ([extraParams objectForKey:@"locationInfo"]) {
        [md setObject:[extraParams objectForKey:@"locationInfo"] forKey:@"locationInfo"];
    }
    
    [self callTheServer:md completetion:completion];
}

///译员直拨---调HTTP接口请求服务器通知译员来Call我。
- (void)callTheTranslator   :(NSString *)trId
        flowId              :(NSString *)flowId
        callerName          :(NSString *)callerName
        callerIcon          :(NSString *)callerIcon
        lineType            :(int)lineType
        extraParams         :(NSDictionary *)extraParams
        completetion        :(TIMCompletionBlock)completion
{
    [self callTheTranslator:trId srcLangId:nil tarLangId:nil flowId:flowId callerName:callerName callerIcon:callerIcon lineType:lineType extraParams:extraParams completetion:completion];
}

- (void)keepAliveWithFlowId:(NSString *)flowId completetion:(TIMCompletionBlock)completion
{
    if (flowId.length == 0) {
        NSDictionary    *userInfo = [NSDictionary dictionaryWithObject:@"flowId 不能为空" forKey:NSLocalizedDescriptionKey];
        NSError         *error = [NSError errorWithDomain:@"" code:60000 userInfo:userInfo];
        completion(nil, error);
        return;
    }
    
    [[TRNetWork sharedManager] requestURLPath:ST_API_keepAliveByMsg httpMethod:TRRequestMethodPost parmas:@{@"flowId":flowId}  completetion:^(id responseObject, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            TRBaseModel *model = [[TRBaseModel alloc] initWithDictionary:responseObject];
            
            if (model.isStatusOK) {
                if ([model.data[@"code"] isEqualToString:@"1"]) {
                    completion(model.data, nil);
                } else {
                    NSString *errorString = @"";
                    
                    if ([model.data[@"code"] isEqualToString:@"2"]) {
                        errorString = @"在接口调用之前订单已经结束   无法保活";
                    } else if ([model.data[@"code"] isEqualToString:@"3"]) {
                        errorString = @"订单状态不是未领取状态  已强制结束  无法保活";
                    }
                    
                    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:errorString forKey:NSLocalizedDescriptionKey];
                    NSError *error = [NSError errorWithDomain:@"" code:60006 userInfo:userInfo];
                    completion(nil, error);
                }
            }
        });
    }];
}

- (void)userReceiveWithFlowId:(NSString *)flowId conversationMode:(NSString *)conversationMode completetion:(TIMCompletionBlock)completion
{
    if ((flowId.length == 0) && completion) {
        completion(0, nil);
        return;
    }
    
    [[TRNetWork sharedManager] requestURLPath:ST_API_userReceive httpMethod:TRRequestMethodPost parmas:@{@"flowId":flowId}  completetion:^(id responseObject, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error && completion) {
                completion(nil, error);
                return;
            }
            
            TRBaseModel *model = [[TRBaseModel alloc] initWithDictionary:responseObject];
            
            if (model.isStatusOK) {
           
                if ([conversationMode isEqualToString:@"IM"]) {
                    [self.orderManger startFlow:flowId linkType: @"ChatWithAgora"];
                } else {
                    [self.orderManger startFlow:flowId linkType:@"agora"];
                }
                
                completion(model.data, nil);
                
                if ([model.data objectForKey:@"agoraAPPKey"]) {
                    NSString *agoraAPPKey = [NSString stringWithFormat:@"%@", [model.data objectForKey:@"agoraAPPKey"]];
                    [AgoraManger sharedInstance].agoraAPPKey = agoraAPPKey;
                }
                
                if ([model.data objectForKey:@"agoraJoinChannelByKey"]) {
                    NSString *agoraJoinChannelByKey = [NSString stringWithFormat:@"%@", [model.data objectForKey:@"agoraJoinChannelByKey"]];
                    [AgoraManger sharedInstance].agoraJoinChannelByKey = agoraJoinChannelByKey;
                }
                
                if ([model.data objectForKey:@"agoraRecordingServiceKey"]) {
                    NSString *agoraRecordingServiceKey = [NSString stringWithFormat:@"%@", [model.data objectForKey:@"agoraRecordingServiceKey"]];
                    [AgoraManger sharedInstance].agoraRecordingServiceKey = agoraRecordingServiceKey;
                }
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self.orderManger userReceiveTheCall];
                });
            } else {
                NSDictionary *userInfo = [NSDictionary dictionaryWithObject:model.msg forKey:NSLocalizedDescriptionKey];
                NSError *error = [NSError errorWithDomain:@"" code:60005 userInfo:userInfo];
                completion(nil, error);
            }
        });
    }];
}

- (NSString *)getLangNameWithLangID:(NSString *)langId
{
    return [TRLanguageFile getLangNameWithLangID:langId];
}

- (void)requestRecommendTranslator:(NSString *)sourceLangId destLangId:(NSString *)destLangId completetion:(void (^)(NSArray <TRTranslator *> *translators, NSError *error))completion
{
    NSDictionary *dic = TRDicWithOAndK(sourceLangId, @"srcLang", destLangId, @"tarLang");
    [[TRNetWork sharedManager] requestURLPath:ST_API_conversation_translatorRecommendation httpMethod:TRRequestMethodPost parmas:dic completetion:^(id responseObject, NSError *error) {
        TRBaseModel *model = [[TRBaseModel alloc] initWithDictionary:responseObject];
        
        if (model.isStatusOK) {
            NSArray *list = model.data[@"list"];
            NSMutableArray *translators = [NSMutableArray arrayWithCapacity:1];
            for (NSInteger i = 0; i < list.count; i++) {
                NSDictionary *dic = list[i];
                TRTranslator *translator = [[TRTranslator  alloc] init];
                [translator setValuesForKeysWithDictionary:dic];
//                [TranslatorManagedObject updateTranslator:translator];
                [translators addObject:translator];
            }
            if (completion) {
                completion(translators, nil);
            }
        } else {
            if (completion) {
                NSDictionary *userInfo = [NSDictionary dictionaryWithObject:model.msg forKey:NSLocalizedDescriptionKey];
                NSError *error = [NSError errorWithDomain:@"" code:60006 userInfo:userInfo];
                completion(nil, error);
            }
        }
    }];
}

- (void)getTranslatorsStatus:(NSString *)translators result:(void (^)(NSArray *results))block
{
    NSDictionary *dic = TRDicWithOAndK(translators, @"translatorIdStr");
    
    [[TRNetWork sharedManager] requestURLPath:ST_API_conversation_searchTransnOnlineStatus httpMethod:TRRequestMethodPost parmas:dic completetion:^(id responseObject, NSError *error) {
        if (error) {
            if (block) {
                block(@[]);
            }
        } else {
            TRBaseModel *model = [[TRBaseModel alloc] initWithDictionary:responseObject];
            
            if (model.isStatusOK) {
                if (block) {
                    block(model.data[@"list"]);
                }
            } else {
                if (block) {
                    block(@[]);
                }
            }
        }
    }];
}

- (void)getTranslatorInfoWithFlowId:(NSString *)flowId completetion:(TIMCompletionBlock)completion
{
    if ([flowId length] == 0) {
        if (completion) {
            completion(nil, [NSError errorWithDomain:@"" code:0 userInfo:nil]);
        }
        
        return;
    }
    
    NSDictionary *dic = TRDicWithOAndK([NSString stringWithFormat:@"%@", flowId], @"flowId");
    [[TRNetWork sharedManager] requestURLPath:ST_API_getTranslatorByFlowId httpMethod:TRRequestMethodPost parmas:dic completetion:^(id responseObject, NSError *error) {
        TRBaseModel *model = [[TRBaseModel alloc] initWithDictionary:responseObject];
        
        if (model.isStatusOK) {
            NSString *translatorId = model.data[@"translatorId"];
            if (translatorId.length >0) {
                if (completion) {
                    completion(responseObject, nil);
                }
                
                return;
            } else {}
            
            if (completion) {
                completion(nil, [NSError errorWithDomain:@"" code:0 userInfo:nil]);
            }
            
            return;
        } else {
            if (completion) {
                completion(nil, [NSError errorWithDomain:@"" code:0 userInfo:nil]);
            }
            
            return;
        }
    }];
}


@end
