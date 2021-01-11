/*!
 *   TransnSDKChatDelegate.h
 *   TransnSDK
 *
 *   Created by 姜政 on 16/10/27.
 *   Copyright © 2018年 Transn. All rights reserved.
 *
 */

#import "TRMessage.h"
#import "TRConstants.h"

/*!
 * 网络通话的网络状态
 */
//typedef NS_ENUM (NSInteger, NetCallNetStatus) {
//    ///非常好
//    NetCallNetStatusVeryGood = 0,
//    ///好
//    NetCallNetStatusGood = 1,
//    ///差
//    NetCallNetStatusBad = 2,
//    ///非常差
//    NetCallNetStatusVeryBad = 3,
//} TRAPIDeprecated("加了前缀");
//
///*!
// *   挂断原因类型：
// */
//typedef NS_ENUM (NSInteger, NetCallDisconnectReason) {
//    /// 0-用户取消
//    UserCancle = 0,
//    /// 1-用户端正常挂断
//    UserComplete = 1,
//    /// 2-译员端正常挂断
//    TransComplete = 2,
//    /// 3-服务端感知译员掉线挂断
//    ServerSensorTransIMOffLine = 3,
//    /// 4-用户端感知译员端掉线挂断
//    UserSensorTransOffLine = 4,
//    /// 5-译员端感知用户端掉线挂断
//    TransSensorUserOffLine = 5,
//    /// 6-用户IM掉线挂断
//    UserIMOffLine = 6,
//    /// 7-译员IM掉线挂断
//    TransIMOffLine = 7,
//    /// 8-译员APP被杀掉挂断
//    TransAppKill = 8,
//    ///transnBox盒子挂断,只有transnBoxApp会收到此消息
//    TransnBox_RingOff = 9,
//}TRAPIDeprecated("加了前缀");

typedef NS_ENUM (NSInteger, TRNetCallNetStatus) {
    ///非常好
    TRNetCallNetStatusVeryGood = 0,
    ///好
    TRNetCallNetStatusGood = 1,
    ///差
    TRNetCallNetStatusBad = 2,
    ///非常差
    TRNetCallNetStatusVeryBad = 3,
} ;

/*!
 *   挂断原因类型：
 */
typedef NS_ENUM (NSInteger, TRNetCallDisconnectReason) {
    /// 0-用户取消
    TRUserCancle = 0,
    /// 1-用户端正常挂断
    TRUserComplete = 1,
    /// 2-译员端正常挂断
    TRTransComplete = 2,
    /// 3-服务端感知译员掉线挂断
    TRServerSensorTransIMOffLine = 3,
    /// 4-用户端感知译员端掉线挂断
    TRUserSensorTransOffLine = 4,
    /// 5-译员端感知用户端掉线挂断
    TRTransSensorUserOffLine = 5,
    /// 6-用户IM掉线挂断
    TRUserIMOffLine = 6,
    /// 7-译员IM掉线挂断
    TRTransIMOffLine = 7,
    /// 8-译员APP被杀掉挂断
    TRTransAppKill = 8,
    ///transnBox盒子挂断,只有transnBoxApp会收到此消息
    TRTransnBox_RingOff = 9,
};

@protocol TransnSDKChatDelegate <NSObject>

@optional

/*!
 *   发送消息状态回调
 *
 *   @param message 消息体 和发送时的message通过messageId比较，如果一样则是同一条消息
 *   @param state 成功\失败
 *   如果是图片消息，在消息发送完成之后，此message对象的image为nil，之前发送的message对象的image不为nil，调用者可以置为nil，可以减少内存消耗
 */
- (void)sendMessage:(TRMessage *)message didCompleteWithState:(TIMMessageSendState)state;

/*!
 *   发送图片消息，专有的一个回调，如果接收此回调，则此回调结束后，会立马把message的image置为nil
 *
 *   @param message 消息对象
 *   @param image 上传的图片
 */
- (void)sendImageMessage:(TRMessage *)message didCompleteUpdateImage:(UIImage *)image;

/*!
 *   接收消息
 *
 *   @param message 消息体
 */
- (void)onRecvMessages:(TRMessage *)message;

///通话建立
- (void)netCallStatusDidconnected;

/*!
 *   通话结束
 *
 *   @param hungUpType 结束的原因
 *   @param returnValue  服务器返回信息
 */
//- (void)netCallStatusDisconnectWithType:(NetCallDisconnectReason)hungUpType orderInfo:(NSDictionary *)returnValue TRAPIDeprecated("加了前缀");
- (void)netCallStatusDisconnectWithType:(TRNetCallDisconnectReason)hungUpType orderInfo:(NSDictionary *)returnValue;

/////开始建立通话，译员已经接单 废弃
// - (void)startBulidLine TRAPIDeprecated("使用新方法 - (void)netCallStatusDidconnected");

///建立通话失败（比如：接听失败）
- (void)bulidLineWithErrorString:(NSString *)errorMsg;

/// 网络状态.2秒返回一次
//- (void)(NetCallNetStatus)status TRAPIDeprecated("加了前缀");

/// 网络状态.2秒返回一次
- (void)onCallNetStatus:(TRNetCallNetStatus)status;

/*!
 *   收到抢单的译员信息，此方法最多会被调用7次（30秒内），跟viewController的ViewWillAppear差不多，会多次调用，接入端需要做判断,防止重复执行
 *
 *   @param translator 译员对象
 */
- (void)onReceiveTranslatorModel:(TRTranslator *)translator;

/*!
 *   收到抢单的译员信息，此方法最多会被调用次（30秒内），跟viewController的ViewWillAppear差不多，会多次调用，接入端需要做判断,防止重复执行
 *
 *   @param username 昵称
 *   @param image 头像
 *   @param translatorId 译员ID
 *   @param translatorRemark mark信息
 */
- (void)receiveTransnerName:(NSString *)username image:(NSString *)image translatorId:(NSString *)translatorId translatorRemark:(NSString *)translatorRemark;// TRAPIDeprecated("使用新方法 -(void)onReceiveTranslatorModel:(TRTranslator *)Translator");

///语音通话连接成功
- (void)voiceConnected;

///语音通话连接断开
- (void)voiceDisconnected;



/*!
 发送的消息包含敏感词
 @param message message对象
 *   "sensitiveWordsList": [
 *   {
 *     "sensitiveLevel": "1",  //敏感级别
 *     "sensitiveWords": [
 *     "高潮",
 *     "裸露"
 *     ]     //当前级别的敏感词有哪些
 *   },
 *   {
 *     "sensitiveLevel": "2",
 *     "sensitiveWords": [
 *     "做爱"
 *     ]
 *   },
 */
- (void)onRecvSensitiveWordsMessage:(TRMessage *)message;
#pragma mark 表示是否能翻译 定制消息，如果有定制，则实现

/*!
 *   定制消息，只有定制的用户的订单会收到的消息,不限次数的回调
 *
 *   @param preTranslateMsg 消息体
 *     flowId: 订单ID
 *     src_messageId：原文IM消息的messageId
 *     chargeType：
 *     101-用户原文是文本
 *     102-用户原文是图片
 *     103-用户原文是语音
 *     lens：长度（文本、图片的字数或语音的时长秒）
 *   @param block 是否可以翻译  .语音模式下，请发YES
 */
- (void)onRecvPreTranslate:(NSDictionary *)preTranslateMsg canTranslate:(void (^)(BOOL canTranslate))block;

#pragma mark TransnBox
/// 收到TransnBox Tips消息
- (void)onRecvTransnBoxTipsMessages:(TRMessage *)message;

@end
