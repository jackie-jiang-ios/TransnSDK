/*!
 *   TransnSDK.h
 *   TransnSDK
 *
 *   Created by 姜政 on 16/6/1.
 *   Copyright © 2018年 Transn. All rights reserved.
 *
 */

#import <Foundation/Foundation.h>
#import "TRConstants.h"
#import "TRMessageStorage.h"
#import "TROrderManger.h"
#import "TRMessage.h"
#import "TRFileObject.h"
#import "TRReservationManager.h"

#import "TRLanguageFile.h"
#import "NSDate+TRExtension.h"
#import "NSObject+TRKeyValue.h"
#import "TRBaseModel.h"
#import "TRConstants.h"
#import "TRError.h"
#import "TRFileDownLoad.h"
#import "TRFileLog.h"
#import "TRNetWork.h"
#import "TRNotification.h"
#import "TROpenUDID.h"
#import "TRSafeJSON.h"





@interface TransnSDK : NSObject
///订单业务的方法基本都是通过此对象的delegate方法回调
@property (nonatomic, copy, readonly) TROrderManger   *orderManger;

@property (nonatomic, strong) TRReservationManager *reservationManager;
///是否显示日志,如果是的话，就会存储日志文件，线上环境建议关闭,默认为NO
@property (nonatomic, assign) BOOL                      showLog;

///是否显示日志,如果是的话，就会存储日志文件，线上环境建议关闭,默认为NO
@property (nonatomic, assign) BOOL                      showMoreLog;//显示更多的日志
/// 降低消耗，默认为YES,登录之后未呼单或呼单结束15分钟之后，默认断开链接.
@property (nonatomic, assign) BOOL                      lowConsumption;

///0~15分钟，默认15，是0就不自动断开,未呼单的时候，才会断开,
@property (nonatomic, strong) NSNumber *autoLoginOutTime;

/*!
 *   账号在其他地方登陆时候会触发
 */
@property (nonatomic, copy) void (^accountOnKickOut)(void);
///自己的用户ID
@property (nonatomic, copy, readonly) NSString *myUserID;
#pragma mark SDK 1.5.1 2017-08-16

/*!
 *   SDK初始化方法
 *
 *   @param appKey 应用的Key
 *   @param appSecret 应用的密码
 *   @param environment 调用模式
 */
+ (void)registerAppKey:(NSString *)appKey appSecret:(NSString *)appSecret environment:(TransnEnvironment)environment;

/*!
 *  登录
 *  @param userId 需要先去服务器注册
 *  @param completion 返回登录错误信息，登录成功error为nil
 */
- (void)loginWithUserId:(NSString *)userId completetion:(void (^)(NSError *error))completion;

/*!
 *  退出登录
 *  @param completion 返回登出错误信息，登录成功error为nil
 */
- (void)loginOut:(void (^)(NSError *error))completion;

/*!
 *   判断是否登录
 *
 *   @return 是否登录
 */
- (BOOL)isLogined;// TRAPIDeprecated("使用新方法isAuthenticated");

/*!
 *   判断是否授权成功了，授权成功了，才可以呼单
 *
 *   @return 是否授权成功
 */
-(BOOL)isAuthenticated;
/*!
 *   获取SDK版本号
 *
 *   @return 例如 "2.0.0"
 */
+ (NSString *)getVersion;

/*!
 *   获取支持的语种列表
 *
 *   @param completion 语种List
 */
- (void)getLanguageList:(void (^)(NSArray *langList))completion;

/*!
 *  按语种请求译员
 *
 *  @param srcLangId 源语种ID
 *  @param tarLangId 目标语种ID
 *  @param flowId 传入flowId时表示保活，一单结束，想要重连，请直连，重传flowdId没用
 *  @param callerName 用户名称
 *  @param callerIcon 用户图像地址
 *  @param serviceType 译员类型 1:（直链接// 2:(仅匹配兼职)// 3:(仅匹配专职)// 4:（匹配所有译员 先兼职,10秒后匹配专职）
 *  @param lineType 订单模式 0: 图文聊天 1：语音和图文
 *  @param isWait //是否等待 0不等待 1等待，请传1
 *  @param extraParams 扩展字段 如    @{@"locationInfo":@"114.409194,30.482325"} 坐标经纬度，字符串类型
 *  @param completion 服务器会返回呼叫是否成功相应信息
 *
 */
- (void)callTheServerSrcLangId  :(NSString *)srcLangId
        tarLangId               :(NSString *)tarLangId
        flowId                  :(NSString *)flowId
        callerName              :(NSString *)callerName
        callerIcon              :(NSString *)callerIcon
        serviceType             :(int)serviceType
        lineType                :(int)lineType
        isWait                  :(int)isWait
        extraParams             :(NSDictionary *)extraParams
        completetion            :(TIMCompletionBlock)completion;

/*!
 *  直连译员
 *
 *  @param trId 译员的ID
 *  @param srcLangId 源语种ID
 *  @param tarLangId 目标语种ID
 *  @param flowId 传入flowId时表示保活，一单结束，想要重连，请直连，重传flowdId没用
 *  @param callerName 用户名称
 *  @param callerIcon 用户图像地址
 *  @param lineType 订单模式 0: 图文聊天 1：语音和图文
 *  @param extraParams 扩展字段 如    @{@"locationInfo":@"114.409194,30.482325"} 坐标经纬度
 *  @param completion 服务器会返回呼叫是否成功相应信息
 *
 */
- (void)callTheTranslator   :(NSString *)trId
        srcLangId           :(NSString *)srcLangId
        tarLangId           :(NSString *)tarLangId
        flowId              :(NSString *)flowId
        callerName          :(NSString *)callerName
        callerIcon          :(NSString *)callerIcon
        lineType            :(int)lineType
        extraParams         :(NSDictionary *)extraParams
        completetion        :(TIMCompletionBlock)completion;

/*!
 *  直接呼叫译员
 *
 *  @param trId 译员的ID
 *  @param flowId 传入flowId时表示保活，一单结束，想要重连，请直连，重传flowdId没用
 *  @param callerName 用户名称
 *  @param callerIcon 用户图像地址
 *  @param lineType 订单模式 0: 图文聊天 1：语音和图文
 *  @param extraParams 扩展字段 如    @{@"locationInfo":@"114.409194,30.482325"} 坐标经纬度，字符串类型
 *  @param completion 服务器会返回呼叫是否成功相应信息
 *
 */
- (void)callTheTranslator   :(NSString *)trId
        flowId              :(NSString *)flowId
        callerName          :(NSString *)callerName
        callerIcon          :(NSString *)callerIcon
        lineType            :(int)lineType
        extraParams         :(NSDictionary *)extraParams
        completetion        :(TIMCompletionBlock)completion TRAPIDeprecated("使用新方法 callTheTranslator:srcLangId:tarLangId:flowId:callerName:callerIcon:lineType:extraParams:completetion:");

#pragma mark 老版本呼单

/*!
 *  带用户信息呼叫
 *
 *  @param trId 译员的ID
 *  @param srcLangId 源语种ID
 *  @param tarLangId 目标语种ID
 *  @param flowId 传入flowId时表示保活，一单结束，想要重连，请直连，重传flowdId没用
 *  @param callerName 用户名称
 *  @param callerIcon 用户图像地址
 *  @param lineType 订单模式 0: 图文聊天 1：语音和图文
 *  @param extraParams 扩展字段 如    @{@"locationInfo":@"114.409194,30.482325"} 坐标经纬度，字符串类型
 *  @param completion 服务器会返回呼叫是否成功相应信息
 *
 */
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
        completetion        :(TIMCompletionBlock)completion TRAPIDeprecated("使用新方法callTheServerSrcLangId:tarLangId:flowId:callerName:callerIcon:serviceType:lineType:isWait:extraParams:completetion:");

/*!
 *  请求服务器分配译员
 *
 *  @param srcLangId 源语种ID
 *  @param tarLangId 目标语种ID
 *  @param flowId 传入flowId时表示保活，一单结束，想要重连，请直连，重传flowdId没用
 *  @param callerName 用户名称
 *  @param callerIcon 用户图像地址
 *  @param serviceType 译员类型 1:（直链接// 2:(仅匹配兼职)// 3:(仅匹配专职)// 4:（匹配所有译员 先兼职,10秒后匹配专职）
 *  @param lineType 订单模式 0: 图文聊天 1：语音和图文
 *  @param isWait //是否等待 0不等待 1等待，请传1
 *  @param extraParams 扩展字段 如    @{@"locationInfo":@"114.409194,30.482325"} 坐标经纬度，字符串类型
 *  @param completion 服务器会返回呼叫是否成功相应信息
 *
 */
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
        completetion            :(TIMCompletionBlock)completion TRAPIDeprecated("使用新方法callTheServerSrcLangId:tarLangId:flowId:callerName:callerIcon:serviceType:lineType:isWait:extraParams:completetion:");

#pragma mark SDK 1.5.0
///TransnSDK类的单利
+ (TransnSDK *)shareManger;


/*!
 通过语种查看译员，查看在线译员

 @param sourceLangId  原语种，多个标签，用逗号分隔
 @param destLangId  目标语种
 @param completion dic和error，如果是网络错误就是error，如果dic不为空，则判断dic中的data中的resource_state字段 1.adequate=译员充足，响应神速 2.absent=抱歉，译员们都不在-_- 3.busy=译员都好忙，呼叫后需稍,这种状态，表示空闲的译员数1-3个,可以呼叫
 */
- (void)requestTranslator:(NSString *)sourceLangId destLangId:(NSString *)destLangId completetion:(TIMCompletionBlock)completion;


/*!
  通过语种ID拿到语种的汉字

 @param langId 语种ID
 @return 汉字
 */
- (NSString *)getLangNameWithLangID:(NSString *)langId;
#pragma mark 获取历史消息，

/*!
  获取每一个订单的消息

 @param flowId 订单ID
 @param block 消息数组
 */
- (void)selectMessagesByFlowId:(NSString *)flowId result:(void (^)(NSArray <TRMessage *> *messages))block;


/*!
 返回该用户和当前连接的译员之间的所有消息

 @param userId 当前用户ID，此ID非login方法中的UserID，基本上此方法，只限SDK内部调用
 @param block 消息数组
 */
- (void)selectMessagesByUserId:(NSString *)userId result:(void (^)(NSArray <TRMessage *> *messages))block;


/*!
 默认返回当前登录SDK的用户和该译员之间所有的消息

 @param translatorId 译员ID
 @param block 消息数组
 */
- (void)selectMessagesByTranslatorId:(NSString *)translatorId result:(void (^)(NSArray <TRMessage *> *messages))block;



/*!
 返回该用户和当前连接的译员之间的所有消息

 @param userId 当前用户ID，此ID非login方法中的UserID，基本上此方法，只限SDK内部调用
 @param translatorId 译员ID
 @param block 消息数组
 */
- (void)selectMessagesByUserId:(NSString *)userId translatorId:(NSString *)translatorId result:(void (^)(NSArray <TRMessage *> *messages))block;

#pragma mark 获取云端聊天消息,目前只支持根据订单ID来查询

/*!
 *   通过flowId查询云端的聊天记录
 *
 *   @param flowId flowId
 *   @param block 消息数组+译员信息+登录SDK的用户ID，
 */
- (void)getTransnCloudMesssagesByFlowId:(NSString *)flowId result:(void (^)(NSArray <TRMessage *> *messages, TRTranslator *translator, NSString *userId))block;



/*!
获取明星译员

 @param sourceLangId  原语种
 @param destLangId 目标语种
 @param completion 译员数组
 */
- (void)requestRecommendTranslator:(NSString *)sourceLangId destLangId:(NSString *)destLangId completetion:(void (^)(NSArray <TRTranslator *> *translators, NSError *error))completion;


/*!
 通过译员ID拼接字符串获取译员状态

 @param translators 译员ID字符串 ID1,ID2,以逗号分隔
 @param block
                     *   {
                     *   "result":"1",
                     *   "data":
                     *   {
                     *   "list" :
                     *   [
                     *   {
                     *   "translatorId":"id1",  //离线
                     *   "status":"TR_OFFLINE",  //离线
                     *   },
                     *   {
                     *   "translatorId":"id2",  //离线
                     *   "status":"TR_ONLINE",  //在线
                     *   } ，
                     *   {
                     *   "translatorId":"id3",  //离线
                     *   "status":"TR_BUSY",  //忙碌
                     *   }
                     *   ]
                     *   }
                     *   }
 */
- (void)getTranslatorsStatus:(NSString *)translators result:(void (^)(NSArray *results))block;

#pragma mark - transnBox+takeeasy接口

/*!
 // 老版本查询消息接口

 @param userID 对方用户ID
 @return TRMessage数组
 */
- (NSArray *)getMessageHistoryWithJID:(NSString *)userID;
- (void)deleteMessageHistoryWithJID:(NSString *)userID;


/*!
TransnBox专用

 @param flowId 订单ID
 */
- (void)callTransnBoxWithFlowId:(NSString *)flowId;


/*!
 留言后调用保活 译员领取后回呼

 @param flowId 订单ID
 @param completion dic和error
 */
- (void)keepAliveWithFlowId:(NSString *)flowId completetion:(TIMCompletionBlock)completion;


/*!
 用户领取译员回呼

 @param flowId 订单ID
 @param conversationMode mode
 @param completion dic和error
 */
- (void)userReceiveWithFlowId:(NSString *)flowId conversationMode:(NSString *)conversationMode completetion:(TIMCompletionBlock)completion;


/*!
 小尾巴业务

 @param flowId 订单ID
 @param completion dic和error
 */
- (void)getTranslatorInfoWithFlowId:(NSString *)flowId completetion:(TIMCompletionBlock)completion;


/*!
 小尾巴业务

 @param completion block
 */
- (void)checkUserCallBackWithCompletion:(TIMCompletionBlock)completion;



@end
