/*!
 *   TROrder.h
 *   TransnSDK
 *
 *   Created by 姜政 on 2018/2/12
 *   Copyright © 2018年 Transn. All rights reserved.
 */

#import <Foundation/Foundation.h>
#import "TRTranslator.h"
#import "TransnSDKChatDelegate.h"
@interface TROrder : NSObject
///每个通话相关的订单ID
@property (nonatomic, copy) NSString *flowId;

//订单类型 文字还是图片
@property (nonatomic,assign,readonly)BOOL   isTextOrder;

//通话类型，sdk内部使用
@property (nonatomic, copy) NSString *linkType;

///当前订单的译员
@property(nonatomic, strong) TRTranslator  *translator;
/**
 *   当前订单时长,客户端的时长跟服务器的时长，存在3秒内的误差,计费以服务端时长为准
 *
 *   @return 返回int值
 */
@property(nonatomic, assign) int orderTime;

///是否正在通话中
@property (nonatomic, assign) BOOL isConnected;

//挂断的原因
@property (nonatomic,assign)TRNetCallDisconnectReason disconnectReason;

/**
 *  与译员进行语音通话，此功能的场景是先跟译员保持IM会话，然后可以转成实时语音，并且保持IM会话
 *  @return 0 请求成功. 调用语音开始后者结束之后，15秒钟之后才能再调用此方法 //如果返回9000，表示点击的太频繁，请15秒钟之后再点击
 */
- (int)contectTranslatorWithVoice;

/**
 *   是否跟译员正在语音通话
 *
 *   @return true of false
 */
- (BOOL)isContectTranslatorWithVoice;

/**
 *  断开与译员进行的语音通话，断开之后，会保留IM会话，如果要直接结束订单，请调用hangupCurrentCall方法,不必调用此方法
 *  @return 0 请求成功.调用语音开始后者结束之后，15秒钟之后才能再调用此方法 //如果返回9000，表示点击的太频繁，请15秒钟之后再点击
 */
- (int)disContectTranslatorWithVoice;

/**
 是否可以切换语音，
 
 @return 如果在15秒内连续切换，就不能，其它就可以
 */
-(BOOL)canSwitchVoice;
@end
