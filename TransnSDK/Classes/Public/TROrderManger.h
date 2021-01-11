/*!
 *   TROrderManger.h
 *   TransnSDK
 *
 *   Created by 姜政 on 16/10/27.
 *   Copyright © 2018年 Transn. All rights reserved.
 *
 */

#import <Foundation/Foundation.h>
#import "TransnSDKChatDelegate.h"
#import "TRMessage.h"
#import "TRConstants.h"
#import "TROrder.h"


@interface TROrderManger : NSObject

@property (nonatomic,strong)TROrder *currentOrder;

///每个通话相关的订单ID
@property (nonatomic, copy) NSString *flowId;// TRAPIDeprecated("使用新方法 currentOrder.flowId");

@property (nonatomic, copy) NSString *linkType;// TRAPIDeprecated("使用新方法 currentOrder.linkType");
///当前订单的译员,挂断通话后，会置为nil
@property(nonatomic, strong) TRTranslator  *translator;// TRAPIDeprecated("使用新方法 currentOrder.translator");

/**
 *   当前订单时长,如果一单结束，另一单接通前，这个值默认还是上一单的值，接通后，会立马置为0，开始计时
 *
 *   @return 返回int值
 */
@property(nonatomic, assign, readonly) int currentOrderTime;// TRAPIDeprecated("使用新方法 currentOrder.currentOrderTime");

///呼叫译员前需要设置delegate，结束通话后需要设置delegate=nil;
@property (nonatomic, weak) id <TransnSDKChatDelegate> delegate;

///是否正在通话中
@property (nonatomic, assign, readonly) BOOL isConnected;// TRAPIDeprecated("使用新方法 currentOrder.isConnected");


// 检查发送Text消息中的敏感词,默认为NO
@property (nonatomic, assign) BOOL checkSendMsgSensitiveWords;

// 检查接收Text消息中的敏感词,默认为NO
@property (nonatomic, assign) BOOL checkRecvMsgSensitiveWords;
/**
 *  挂断或者取消当前订单（无论是文本翻译还是语音通话翻译都需要调用接口挂断）,只要是调用了呼单的方法，一定要调用此方法，
 */
- (void)hangupCurrentCall;

/**
 *  挂断或者取消回呼单
 */
- (void)hangupCallWithFlowId:(NSString *)flowId;

/**
 *  与译员进行语音通话，此功能的场景是先跟译员保持IM会话，然后可以转成实时语音，并且保持IM会话
 *  @return 0 请求成功. 调用语音开始后者结束之后，15秒钟之后才能再调用此方法 //如果返回9000，表示点击的太频繁，请15秒钟之后再点击
 */
- (int)contectTranslatorWithVoice;// TRAPIDeprecated("使用新方法 [currentOrder contectTranslatorWithVoice]");

/**
 *   是否跟译员正在语音通话
 *
 *   @return true of false
 */
- (BOOL)isContectTranslatorWithVoice;// TRAPIDeprecated("使用新方法 [currentOrder contectTranslatorWithVoice]");

/**
 *  断开与译员进行的语音通话，断开之后，会保留IM会话，如果要直接结束订单，请调用hangupCurrentCall方法
 *  @return 0 请求成功.调用语音开始后者结束之后，15秒钟之后才能再调用此方法 //如果返回9000，表示点击的太频繁，请15秒钟之后再点击
 */
- (int)disContectTranslatorWithVoice;// TRAPIDeprecated("使用新方法 [currentOrder contectTranslatorWithVoice]");

/**
 是否可以切换语音，
 
 @return 如果在15秒内连续切换，就不能，其它就可以
 */
-(BOOL)canSwitchVoice;// TRAPIDeprecated("使用新方法 [currentOrder contectTranslatorWithVoice]");
/**
 *  发送文本消息给对方.只有译员接单了，才会发送出去,译员接通前不会发送.
 *
 *  @param text 文本内容
 *
 */
- (TRMessage *)sendTextMessage:(NSString *)text;

/**
 *  发送图片消息给对方.译员接通前不会发送
 *
 *  @param img 图片 ,图片SDK未压缩，故调用此方法前，需要自己去压缩一下，不然太大了，可能浪费资源或者影响使用
 *
 */
- (TRMessage *)sendImageMessage:(UIImage *)img;

/**
 *  发送语音消息给对方.译员接通前不会发送
 *
 *  @param filePath 语音文件本地路径
 *
 */
- (TRMessage *)sendVoiceMessage:(NSString *)filePath voiceSize:(NSString *)voiceSize;

/**
 *  重新发送消息.译员接通前不会发送
 *
 *  @param message TRMessage
 *
 */
- (void)reSendMessage:(TRMessage *)message;

/**
 *  发送TIPS消息
 *
 *  @param text 发送系统tip消息
 *
 */
- (void)sendSystemTipsMesssage:(NSString *)text;

/**
 *  设置通话静音模式
 *
 *  @param mute 是否开启静音
 *
 *  @discussion 切换订单类型将丢失该设置
 */
- (void)setMute:(BOOL)mute;

/**
 *  设置通话扬声器模式
 *
 *  @param useSpeaker 是否开启扬声器
 *
 *  @discussion 切换订单类型将丢失该设置
 */
- (void)setSpeaker:(BOOL)useSpeaker;


- (int)setDefaultAudioRouteToSpeakerphone:(BOOL)defaultToSpeaker;


///**
// *  Sets the speakerphone volume. The speaker volume could be adjust by MPMusicPlayerController and other iOS API easily.
// *
// *  @param volume between 0 (lowest volume) to 255 (highest volume).
// *
// */
//- (void)setSpeakerphoneVolume:(NSUInteger)volume;
//
//
///**
// *  Enables to report to the application about the volume of the speakers.
// *
// *  @param interval Specifies the time interval between two consecutive volume indications.
// <=0: Disables volume indication.
// >0 : The volume indication interval in milliseconds. Recommandation: >=200ms.
// *  @param smooth   The smoothing factor. Recommended: 3.
// *
// */
//- (void)enableAudioVolumeIndication:(NSInteger)interval
//                            smooth:(NSInteger)smooth;


//#pragma mark 语音的同时，播放音频文件
/**
// 指定本地音频文件来和麦克风采集的音频流进行混音和替换(用音频文件替换麦克风采集的音频流)， 可以通过参数选择是否让对方听到本地播放的音频和指定循环播放的次数。该 API 也支持播放在线音乐。
// 
// @param filePath 指定需要混音的本地音频文件名和文件路径名:
// 支持以下音频格式: mp3, aac, m4a, 3gp, wav, flac
// @param loopback True: 只有本地可以听到混音或替换后的音频流  False: 本地和对方都可以听到混音或替换后的音频流
// @param replace True: 音频文件内容将会替换本地录音的音频流  False: 音频文件内容将会和麦克风采集的音频流进行混音
// @param cycle 指定音频文件循环播放的次数: 正整数: 循环的次数 -1: 无限循环
// @return 0: 方法调用成功 <0: 方法调用失败
 */
- (int)startAudioMixing:(NSString*) filePath
               loopback:(BOOL) loopback
                replace:(BOOL) replace
                  cycle:(NSInteger) cycle
                didFinish:(void (^)(void))didFinish;


/**
 停止播放伴奏 (stopAudioMixing)
 
 @return 0：方法调用成功 <0: 方法调用失败
 */
- (int)stopAudioMixing;


///**
// 暂停播放伴奏 (pauseAudioMixing)
// 
// @return 0：方法调用成功 <0: 方法调用失败
// */
//- (int)pauseAudioMixing;
//
//
///**
// 恢复播放伴奏 (resumeAudioMixing)
// 
// @return 0：方法调用成功 <0: 方法调用失败
// */
//- (int)resumeAudioMixing;
//
//
///**
// 调节伴奏音量 (adjustAudioMixingVolume)
// 
// @param volume 伴奏音量范围为 0~100。默认 100 为原始文件音量
// @return 0：方法调用成功 <0: 方法调用失败
// */
//- (int)adjustAudioMixingVolume:(NSInteger) volume;
//
//
///**
// 该方法获取伴奏时长，单位为毫秒。请在频道内调用该方法。
// 
// @return 0：方法调用成功 <0: 方法调用失败
// */
//- (int)getAudioMixingDuration;
//
//
///**
// 获取伴奏播放进度 (getAudioMixingCurrentPosition)
// 
// @return 0：方法调用成功 <0: 方法调用失败
// */
//- (int)getAudioMixingCurrentPosition;
//
//
///**
// 拖动语音进度条 (setAudioMixingPosition)
// 
// @param pos 整数。进度条位置，单位为毫秒
// @return 0：方法调用成功 <0: 方法调用失败
// */
//- (int)setAudioMixingPosition:(NSInteger) pos;

/**
 *    正在输入
 */
- (void)sendComposingChatToUser;

/**
 *    暂停输入
 */
- (void)sendPausedChatToUser;

///TransnBox专用
- (void)callTransnBoxWithFlowId:(NSString *)flowId;

///用户领取译员回呼 小尾巴专用
- (void)userReceiveTheCall;


/**
 *   三方通话
 *
 *   @param phone 手机号
 *   @param room 房间
 *   @param completion 返回结果
 */
- (void)addThirdPartPhone:(NSString *)phone room:(NSString *)room completetion:(TIMCompletionBlock)completion;

/**
 *   译员评价
 *   @param flowId  订单标识
 *   @param comment 评价内容
 *   @param star 评分
 *   @param completion 返回结果
 */
- (void)evaluateOrder:(NSString *)flowId comment:(NSString *)comment star:(int)star completetion:(TIMCompletionBlock)completion;

@end
