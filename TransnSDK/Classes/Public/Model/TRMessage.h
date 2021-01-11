/*!
 *   TRMessage.h
 *   TransnSDK
 *
 *   Created by 姜政 on 15/9/4.
 *   Copyright © 2018年 Transn. All rights reserved.
 *
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "TRTranslator.h"

@class XMPPMessage;

/*!
 *    消息内容类型枚举
 */
typedef NS_ENUM (NSInteger, TransnIMMessageType) {
    /*!文本消息*/
    TIMMessageTypeText = 0,
    /*!图片消息*/
    TIMMessageTypeImage = 1,
    /*!语音消息*/
    TIMMessageTypeVocie = 2,
    /*!TrasnsnBoxTips消息，页面无关的消息*/
    TIMMessageTypeTips = 3,
    /*!自定义提醒消息 。译员端专用 如“来自小尾巴的消息,用于自定义消息*/
    TIMMessageTypeInfo = 5,
    /*!自定义提醒消息 。如：小尾巴中“译员已接单,用于自定义消息*/
    TIMMessageTypeNotification = 6,
    /*!复合消息 带原文和答案，此时就要看paymentMessageType字段*/
    TIMMessageTypePaymentMessage = 7,
    /*!推荐消息，推荐套餐之内，老版本小尾巴有，其它无*/
    TIMMessageTypeRecommandMessage = 10,
};

/*!
 *    消息发送状态
 */
typedef NS_ENUM (NSInteger, TIMMessageSendState) {
    /*!发送失败*/
    TIMMessageSendStatefail,
    /*!发送中*/
    TIMMessageSendStateSending,
    /*!发送成功*/
    TIMMessageSendStateSuccess,
};

/*!
 *  复合消息内容类型枚举
 */
typedef NS_ENUM (NSInteger, PaymentMsgType) {
    /*!问：文字   答：文字 */
    PaymentMsgTypeText2Text = 10,
    /*!问：文字   答：语音 */
    PaymentMsgTypeText2Voice = 11,
    /*!问: 图片   答：文字 */
    PaymentMsgTypeImage2Text = 12,
    /*!问：图片   答：语音*/
    PaymentMsgTypeImage2Voice = 13,
    /*!问：语音   答：文字 */
    PaymentMsgTypeVoice2Text = 14,
    /*!问：语音  答：语音 */
    PaymentMsgTypeVoice2Voice = 15,
};

#pragma mark TRMessageDirection - 消息的方向

/*!
 *   消息的方向
 */
typedef NS_ENUM (NSUInteger, TRMessageDirection) {
    /*!发送*/
    MessageDirection_SEND = 1,
    /*!接收*/
    MessageDirection_RECEIVE = 2,
};

@interface TRMessage : NSObject

/**
 *   通过XMPPMsg创建一条消息，SDK内部使用
 *
 *   @param xmppMsg xmppMessage
 *   @return 返回一个TRMessage对象
 */
- (instancetype)initWithMessage:(XMPPMessage *)xmppMsg;

/**
 *   创建一条文本消息
 *
 *   @param content 文本内容
 *   @param userID 用户ID
 *   @return 返回一个TRMessage对象
 */
- (instancetype)initWithWithTextContent:(NSString *)content formUserID:(NSString *)userID;

/**
 *   创建一条图片消息
 *   @abstract 译员端专用
 *   @param content 图片地址
 *   @param userID 用户ID
 *   @return 返回一个TRMessage对象
 */
- (instancetype)initWithWithImageContent:(NSString *)content formUserID:(NSString *)userID;

/**
 *   创建一条语音消息
 *   @abstract 译员端专用
 *   @param content 语音地址和语音长度的dict转成的json字符串
 *   @param userID 用户ID
 *   @return 返回一个TRMessage对象
 */
- (instancetype)initWithWithVoiceContent:(NSString *)content formUserID:(NSString *)userID;

/**
 *   创建一条自定义消息,不会存储
 *   @abstract 译员端专用，此消息不会发生
 *   @param content  文本
 *   @param userID 用户ID
 *   @return 返回一个TRMessage对象
 */
- (instancetype)initWithWithInfoContent:(NSString *)content formUserID:(NSString *)userID;

/**
 *   创建一条自定义消息,不会存储,如小尾巴“译员已接单”
 *   @abstract  此消息不会发生
 *   @param content  文本
 *   @param userID 用户ID
 *   @return 返回一个TRMessage对象
 */
- (instancetype)initWithWithNotificationContent:(NSString *)content formUserID:(NSString *)userID;

/// 发送状态 成功、失败、发送中
@property (nonatomic, assign) TIMMessageSendState   sendState;

/// 消息类型：发送、接收
@property (nonatomic, assign) TRMessageDirection    messageDirection;

/// 作用同上，是我发送的消息还是接收到的消息
@property (nonatomic, assign, readonly) BOOL        isMyself;

/// 发送者ID ,主要用于未登录时，直接通过flowId获取消息记录时
@property (nonatomic, copy, readonly) NSString *formId;

/// 接收者ID ,未登录时，直接通过flowId获取消息记录时，通过此字段和译员ID比较,判断是接收还是发送消息
@property (nonatomic, copy, readonly) NSString *toId;

/// 消息ID，同一个用户来说是唯一的
@property (nonatomic, copy, readonly) NSString *messageID;

/// 原文消息ID，只有PayMent消息才会有值
@property (nonatomic, copy, readonly) NSString *orginMessageId;

/// 消息内容
@property (nonatomic, copy, readonly) NSString *content;

/// 没有值，无用属性
@property (nonatomic, copy) NSString *timeFormat;

/// 发送时间
@property (nonatomic, strong) NSDate *timestamp;

/// 消息类型
@property (nonatomic, assign, readonly) TransnIMMessageType messageType;

///复合消息类型 （即答案、译文的类型）
@property (nonatomic, assign) PaymentMsgType paymentMessageType;

/// 译员端界面用到的属性.是否允许复制
@property (nonatomic, assign) BOOL isHideCopy;


/*!
 *   图片消息属性，如果是自己发送的图片消息，则为发送的图片，如果是接收的消息就没值
 *    MORE：自己发送的图片，在发送成功后，会把image至为nil，可以通过imageUrl获取该图片
 *         发送失败的消息，如果是因为图片上传失败，则此对象可以获取到之前的图片
 *         发送失败的消息，如果是因为图片上传失败，获取云端消息时，是没有这条消息的，因为都没发出去，只存在了本地
 */
@property (nonatomic, strong) UIImage *image;

/// 图片消息属性，表示图片链接，如果图片上传失败，则为nil
@property (nonatomic, copy) NSString *imageUrl;

/// XMPP消息对象
@property (nonatomic, strong) XMPPMessage *exMessage;

/// 译员端用到的属性，界面上显示“已经开始翻译”
@property (nonatomic, copy) NSString *extContent;

/// 语音消息属性，表示时长，1~60 字符串，如果是复合消息，则表示原文的语音文件时长
@property (nonatomic, copy) NSString *voiceSize;

/// 语音消息属性，表示语音文件链接，如果是复合消息，则表示原文的语音文件链接， 由于兼容PC译员端，语音文件都是MP3格式
@property (nonatomic, copy) NSString *voiceUrl;

/// 语音消息属性，发送语音文件时，对应的本地文件路径- (TRMessage *)sendVoiceMessage:(NSString *)filePath voiceSize:(NSString *)voiceSize; 对应此方法中的filePath
@property (nonatomic, copy) NSString *voicelocalUrl;

/// 无用属性 答案只能是文字、或者语音文件，为nil
@property (nonatomic, strong) UIImage *translateImage;

/// 无用属性 答案只能是文字、或者语音文件，
@property (nonatomic, copy) NSString *translateImageUrl;

///复合语音消息属性，表示时长，1~60 字符串  只有在复合消息中才有值，表示译文的语音文件时长
@property (nonatomic, copy) NSString *translateVoiceSize;

///复合语音消息属性，表示时长，1~60 字符串  只有在复合消息中才有值，表示译文的语音文件链接
@property (nonatomic, copy) NSString *translateVoiceUrl;

/// 无用属性
@property (nonatomic, copy) NSString *translateVoiceLocalUrl;

///复合文字消息属性，表示译文， 只有在复合消息中才有值，
@property (nonatomic, copy) NSString *translateContent;

/// 译员对象 查询历史消息，才可以获得译员信息.
@property (nonatomic, strong) TRTranslator *translatorMb;

/// 统计出来的文本字数
@property(nonatomic, assign) int lensCount;


///根据1级敏感词过滤后的原文,用*号替换了敏感词原文
@property (nonatomic, copy, readonly) NSString *newContent;

///根据1级敏感词过滤后的译文,*号替换了敏感词译文
@property (nonatomic, copy, readonly) NSString *newTranslatedContent;

/*!
 * 敏感词数组
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
@property (nonatomic, strong) NSArray *sensitiveWords;

///是否含有1~2级的敏感词
- (BOOL)isHaveSensitiveWords;

@end
