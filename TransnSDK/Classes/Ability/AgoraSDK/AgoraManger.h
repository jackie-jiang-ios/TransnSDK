//
//  AgoraManger.h
//  Transner
//
//  Created by VanRo on 16/9/2.
//  Copyright © 2016年 Transn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AgoraRtcKit/AgoraRtcEngineKit.h>

@interface AgoraManger : NSObject

+ (instancetype)sharedInstance;

@property (nonatomic, copy) NSString    *agoraAPPKey;
@property (nonatomic, copy) NSString    *agoraJoinChannelByKey;
@property (nonatomic, copy) NSString    *agoraRecordingServiceKey;
@property (nonatomic, assign) BOOL    defaultToSpeaker;
- (int)callWithRoomID:(NSString *)roomId;

/////没有通话的时候是nil
// - (NSString *)getCallId;

- (int)hangUp;

- (void)setSpeaker:(BOOL)isSpeakerOn;

- (void)setMute:(BOOL)isMute;

 //@return * 0: Success. * < 0: Failure.
- (int)setDefaultAudioRouteToSpeakerphone:(BOOL)defaultToSpeaker;


///**
// *  Sets the speakerphone volume. The speaker volume could be adjust by MPMusicPlayerController and other iOS API easily.
// *
// *  @param volume between 0 (lowest volume) to 255 (highest volume).
// *
// *  @return 0 when executed successfully. return negative value if failed.
// */
//- (int)setSpeakerphoneVolume:(NSUInteger)volume __deprecated;





/**
 *  Enables to report to the application about the volume of the speakers.
 *
 *  @param interval Specifies the time interval between two consecutive volume indications.
 <=0: Disables volume indication.
 >0 : The volume indication interval in milliseconds. Recommandation: >=200ms.
 *  @param smooth   The smoothing factor. Recommended: 3.
 *
 *  @return 0 when executed successfully. return negative value if failed.
 */
- (int)enableAudioVolumeIndication:(NSInteger)interval
                            smooth:(NSInteger)smooth;

- (BOOL)isConnected;

@property(nonatomic, copy) void (^callStatusdidLeaveChannelWithStats)(AgoraChannelStats *stats);

@property(nonatomic, copy) void (^callDidDisconnected)(void);
@property(nonatomic, copy) void (^callDidconnected)(void);

@property(nonatomic, copy) void (^audioQuality)(NSUInteger quality);


///**
//指定本地音频文件来和麦克风采集的音频流进行混音和替换(用音频文件替换麦克风采集的音频流)， 可以通过参数选择是否让对方听到本地播放的音频和指定循环播放的次数。该 API 也支持播放在线音乐。
//
// @param filePath 指定需要混音的本地音频文件名和文件路径名:
// 支持以下音频格式: mp3, aac, m4a, 3gp, wav, flac
// @param loopback True: 只有本地可以听到混音或替换后的音频流  False: 本地和对方都可以听到混音或替换后的音频流
// @param replace True: 音频文件内容将会替换本地录音的音频流  False: 音频文件内容将会和麦克风采集的音频流进行混音
// @param cycle 指定音频文件循环播放的次数: 正整数: 循环的次数 -1: 无限循环
// @param playTime 时长
// @return 0: 方法调用成功 <0: 方法调用失败
// */
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
//
//
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
@end
