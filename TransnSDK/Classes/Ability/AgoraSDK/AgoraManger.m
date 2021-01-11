//
//  AgoraManger.m
//  Transner
//
//  Created by VanRo on 16/9/2.
//  Copyright © 2016年 Transn. All rights reserved.
//

#import "AgoraManger.h"
#import <CommonCrypto/CommonDigest.h>
#import "TRConstants.h"


// static NSString *const AgoraMangerKey = @"21e4ffbb382c4212b1b2fd203b2cfa07";

@interface AgoraManger () <AgoraRtcEngineDelegate>
{}

@property (strong, nonatomic) AgoraRtcEngineKit *agoraRtcEngine;
@property (nonatomic,copy)void (^didFinishPlayFileBlock)(void);
@end

@implementation AgoraManger

static AgoraManger *_instance;

#pragma mark  - init

+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        _instance = [[AgoraManger alloc] init];
//        TRLog(@"声网版本:%@",[AgoraRtcEngineKit getSdkVersion]);
//        TRLog(@"agora 版本:%@",[AgoraRtcEngineKit getSdkVersion]);
    });
    
    return _instance;
}

- (NSString *)getCallId
{
    return [_agoraRtcEngine getCallId];
}

- (BOOL)isConnected
{
    BOOL b = [[self getCallId] length] > 0;
    TRLog(@"是否进入语音通话房间:%@",@(b));
    return b;
}

+ (NSString *)encrypt32MD5:(NSString *)encryptStr
{
    if ([encryptStr length] == 0) {
        return @"";
    }
    
    const char      *cStr = [encryptStr UTF8String];
    unsigned char   result[32];
    CC_MD5(cStr, (CC_LONG)strlen(cStr), result);
    return [[NSString stringWithFormat:
             @"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
             result[0], result[1], result[2], result[3],
             result[4], result[5], result[6], result[7],
             result[8], result[9], result[10], result[11],
             result[12], result[13], result[14], result[15]
             ] lowercaseString];
}

- (int)callWithRoomID:(NSString *)roomId
{
    [self.agoraRtcEngine leaveChannel:nil];
    
    if ([_agoraAPPKey length] == 0) {
        _agoraAPPKey = @"21e4ffbb382c4212b1b2fd203b2cfa07";
    }
    
    TRLog(@"TrasnsnSDK内部打印:---用户准备进入语音聊天室");
    NSString *roomId_MD5Str = [[AgoraManger encrypt32MD5:roomId] lowercaseString];
    _agoraRtcEngine = [AgoraRtcEngineKit sharedEngineWithAppId:_agoraAPPKey delegate:_instance];
//    [_agoraRtcEngine setLogFilter:8];
    
    //    if ([_agoraEncryptionSecret length] > 0) {
    //        [_agoraRtcEngine setEncryptionMode:_agoraEncryptionMode];
    //        [_agoraRtcEngine setEncryptionSecret:_agoraEncryptionSecret];
    //    }
    [_agoraRtcEngine setDefaultAudioRouteToSpeakerphone:_defaultToSpeaker];
    NSString *joinChannelByKey = nil;
    
    if ([self.agoraJoinChannelByKey length] > 0) {
        joinChannelByKey = self.agoraJoinChannelByKey;
    }
//    [self.agoraRtcEngine setVoiceOnlyMode:YES];
 
//     [self.agoraRtcEngine setAudioProfile:AgoraRtc_AudioProfile_Default scenario:AgoraRtc_AudioScenario_GameStreaming];
    __weak typeof(self) weakSelf = self;
    return [self.agoraRtcEngine joinChannelByToken:joinChannelByKey channelId:roomId_MD5Str info:nil uid:2 joinSuccess:^(NSString * _Nonnull channel, NSUInteger uid, NSInteger elapsed) {
        if ([weakSelf.agoraRecordingServiceKey length] > 0) {
//            [weakSelf.agoraRtcEngine startRecordingService:weakSelf.agoraRecordingServiceKey];
            TRLog(@"调用服务器开始录音");
        }
        [weakSelf setUp];
    }];
//    return [self.agoraRtcEngine joinChannelByKey:joinChannelByKey channelName:roomId_MD5Str info:nil uid:2 joinSuccess:^(NSString *channel, NSUInteger uid, NSInteger elapsed) {
//        if ([weakSelf.agoraRecordingServiceKey length] > 0) {
//            [weakSelf.agoraRtcEngine startRecordingService:weakSelf.agoraRecordingServiceKey];
//            TRLog(@"调用服务器开始录音");
//        }
//    }];
}
-(void)setUp{
    if (_defaultToSpeaker) {
        [_agoraRtcEngine setEnableSpeakerphone:true];
    }
}

- (int)hangUp
{
    if ([_agoraRecordingServiceKey length] > 0) {
//        int result = [_agoraRtcEngine stopRecordingService:_agoraRecordingServiceKey];
//        TRLog(@"调用服务器结束录音 : %d",result);
    }
    
    return [self.agoraRtcEngine leaveChannel:nil];
}

- (void)setSpeaker:(BOOL)isSpeakerOn
{
    [self.agoraRtcEngine setEnableSpeakerphone:isSpeakerOn];
}

- (void)setMute:(BOOL)isMute
{
    [self.agoraRtcEngine muteLocalAudioStream:isMute];
}
- (int)setDefaultAudioRouteToSpeakerphone:(BOOL)defaultToSpeaker{
    _defaultToSpeaker = defaultToSpeaker;
    return 0;
}
//- (int)setSpeakerphoneVolume:(NSUInteger)volume{
//    return  [self.agoraRtcEngine setdev:volume];
//}





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
//- (int)enableAudioVolumeIndication:(NSInteger)interval
//                            smooth:(NSInteger)smooth{
//   return  [self.agoraRtcEngine enableAudioVolumeIndication:interval smooth:smooth];
//
//}

#pragma mark  - AgoraRtcEngine Delegate
/** Occurs when the user leaves the channel.
 
 When the app calls the [leaveChannel]([AgoraRtcEngineKit leaveChannel:]) method, this callback notifies the app that the user leaves the channel.
 
 With this callback, the app retrieves information, such as the call duration and the statistics of the data received/transmitted by [audioQualityOfUid]([AgoraRtcEngineDelegate rtcEngine:audioQualityOfUid:quality:delay:lost:]).
 
 @param engine AgoraRtcEngineKit object
 @param stats  Statistics of the call: AgoraChannelStats
 */
- (void)rtcEngine:(AgoraRtcEngineKit * _Nonnull)engine didLeaveChannelWithStats:(AgoraChannelStats * _Nonnull)stats{
    if (_callStatusdidLeaveChannelWithStats) {
        _callStatusdidLeaveChannelWithStats(stats);
    }
}

/** Reports an error during SDK runtime.
 
 In most cases, the SDK cannot fix the issue and resume running. The SDK requires the app to take action or informs the user about the issue.
 
 For example, the SDK reports an AgoraErrorCodeStartCall = 1002 error when failing to initialize a call. The app informs the user that the call initialization failed and invokes the [leaveChannel]([AgoraRtcEngineKit leaveChannel:]) method to leave the channel.
 
 See [AgoraErrorCode](AgoraErrorCode) for details.
 
 @param engine    AgoraRtcEngineKit object
 @param errorCode AgoraErrorCode
 */
- (void)rtcEngine:(AgoraRtcEngineKit * _Nonnull)engine didOccurError:(AgoraErrorCode)errorCode{
    NSString *errorStr = [NSString stringWithFormat:@"AgoraRtcErrorCodes: %lu", (long)errorCode];
    TRLog(@"errorStr %@",errorStr);
}

/** Occurs when a user or host joins the channel. Same as [userJoinedBlock]([AgoraRtcEngineKit userJoinedBlock:]).
 
 - Communication channel: This callback notifies the app that another user joins the channel. If other users are already in the channel, the SDK also reports to the app on the existing users.
 - Live-broadcast channel: This callback notifies the app that the host joins the channel. If other hosts are already in the channel, the SDK also reports to the app on the existing hosts. Agora recommends limiting the number of hosts to 17.
 
 **Note:**
 
 In the live broadcast channels:
 
 * The host receives the callback when another host joins the channel.
 * The audience in the channel receives the callback when a new host joins the channel.
 * When a web application joins the channel, this callback is triggered as long as the web application publishes streams.
 
 @param engine  AgoraRtcEngineKit object.
 @param uid     ID of the user or host who joins the channel. If the `uid` is specified in the [joinChannelByToken]([AgoraRtcEngineKit joinChannelByToken:channelId:info:uid:joinSuccess:]) method, the specified ID is returned. If the `uid` is not specified in the joinChannelByToken method, the Agora server automatically assigns a `uid`.
 @param elapsed Time elapsed (ms) from the newly joined user/host calling [joinChannelByToken]([AgoraRtcEngineKit joinChannelByToken:channelId:info:uid:joinSuccess:]) or [setClientRole]([AgoraRtcEngineKit setClientRole:]) until this callback is triggered.
 */
- (void)rtcEngine:(AgoraRtcEngineKit * _Nonnull)engine didJoinedOfUid:(NSUInteger)uid elapsed:(NSInteger)elapsed{
    TRLog(@"uid : %lu", (unsigned long)uid);
    
    if (uid == 1) {// 表示是是译员
        TRLog(@"TrasnsnSDK内部打印:---译员已经进入语音聊天室");
        if (_callDidconnected) {
            _callDidconnected();
        }
    }
}

/** Occurs when a remote user (Communication)/host (Live Broadcast) leaves the channel. Same as [userOfflineBlock]([AgoraRtcEngineKit userOfflineBlock:]).
 
 There are two reasons for users to be offline:
 
 - Leave the channel: When the user/host leaves the channel, the user/host sends a goodbye message. When the message is received, the SDK assumes that the user/host leaves the channel.
 - Drop offline: When no data packet of the user or host is received for a certain period of time (20 seconds for the communication profile, and more for the live broadcast profile), the SDK assumes that the user/host drops offline. Unreliable network connections may lead to false detection, so Agora recommends using a signaling system for more reliable offline detection.
 
 @param engine AgoraRtcEngineKit object
 @param uid    ID of the user or host who leaves the channel or goes offline.
 @param reason Reason why the user goes offline, see AgoraUserOfflineReason for details.
 */
- (void)rtcEngine:(AgoraRtcEngineKit * _Nonnull)engine didOfflineOfUid:(NSUInteger)uid reason:(AgoraUserOfflineReason)reason{
    if (uid == 3) {
       //后台
    }else{
        if (uid == 1) {
             TRLog(@"---译员退出语音聊天室");
        }else {
             TRLog(@"---用户退出语音聊天室");
            if (_callDidDisconnected) {
                _callDidDisconnected();
            }
        }
      
    }
}
//- (void)rtcEngine:(AgoraRtcEngineKit *)engine reportAudioVolumeIndicationOfSpeakers:(NSArray*)speakers totalVolume:(NSInteger)totalVolume{
//    for (NSInteger i=0; i<speakers.count; i++) {
//        AgoraRtcAudioVolumeInfo *info = speakers[i];
//        TRLog(@"用户：%@；音量：%@",@(info.uid),@(info.volume));
//    }
//}


/** Occurs when a user rejoins the channel.
 
 If the client loses connection with the server because of network problems, the SDK automatically attempts to reconnect and then triggers this callback upon reconnection, indicating that the user rejoins the channel with the assigned channel ID and user ID.
 
 @param engine  AgoraRtcEngineKit object.
 @param channel Channel name.
 @param uid     User ID. If the `uid` is specified in the [joinChannelByToken]([AgoraRtcEngineKit joinChannelByToken:channelId:info:uid:joinSuccess:]) method, the specified ID is returned. If the user ID is not specified when joinChannel is called, the server automatically assigns a `uid`.
 @param elapsed Time elapsed (ms) from starting to reconnect to successful reconnection.
 */
- (void)rtcEngine:(AgoraRtcEngineKit * _Nonnull)engine didRejoinChannel:(NSString * _Nonnull)channel withUid:(NSUInteger)uid elapsed:(NSInteger) elapsed{
    
}

// 掉线
/** Occurs when the SDK cannot reconnect to Agora's edge server 10 seconds after its connection to the server is interrupted.
 
 This callback is triggered when the SDK cannot connect to the server 10 seconds after calling [joinChannelByToken]([AgoraRtcEngineKit joinChannelByToken:channelId:info:uid:joinSuccess:]), regardless of whether the SDK is in the channel or not.
 
 This callback is different from [rtcEngineConnectionDidInterrupted]([AgoraRtcEngineDelegate rtcEngineConnectionDidInterrupted:]):
 
 - The [rtcEngineConnectionDidInterrupted]([AgoraRtcEngineDelegate rtcEngineConnectionDidInterrupted:]) callback is triggered when the SDK loses connection with the server for more than four seconds after the SDK successfully joins the channel.
 - The [rtcEngineConnectionDidLost]([AgoraRtcEngineDelegate rtcEngineConnectionDidLost:]) callback is triggered when the SDK loses connection with the server for more than 10 seconds, regardless of whether the SDK joins the channel or not.
 
 For both callbacks, the SDK tries to reconnect to the server until the app calls [leaveChannel]([AgoraRtcEngineKit leaveChannel:]).
 
 @param engine AgoraRtcEngineKit object
 */
- (void)rtcEngineConnectionDidLost:(AgoraRtcEngineKit * _Nonnull)engine{
}

// NIMNetCallNetStatusVeryGood = 0,
// NIMNetCallNetStatusGood     = 1,
// NIMNetCallNetStatusBad      = 2,
// NIMNetCallNetStatusVeryBad  = 3,
/** Reports the audio quality of the remote user. Same as [audioQualityBlock]([AgoraRtcEngineKit audioQualityBlock:]).
 
 **DEPRECATED** from v2.3.2, use [remoteAudioStats]([AgoraRtcEngineDelegate rtcEngine:remoteAudioStats:]) instead.
 
 Triggered once every two seconds, this callback reports the audio quality of each remote user/host sending the audio stream. If a channel has multiple users/hosts sending audio streams, then this callback will be triggered as many times.
 
 @see [remoteAudioStats]([AgoraRtcEngineDelegate rtcEngine:remoteAudioStats:])
 @param engine  AgoraRtcEngineKit object.
 @param uid     User ID of the speaker.
 @param quality Audio quality of the user, see AgoraNetworkQuality.
 @param delay   Time delay (ms) of the audio packet from the sender to the receiver, including the time delay from audio sampling pre-processing, transmission, and the jitter buffer.
 @param lost    Packet loss rate (%) of the audio packet sent from the sender to the receiver.
 */
- (void)rtcEngine:(AgoraRtcEngineKit * _Nonnull)engine audioQualityOfUid:(NSUInteger)uid quality:(AgoraNetworkQuality)quality delay:(NSUInteger)delay lost:(NSUInteger)lost
{
    int i = 0;
    if (quality < 2) {
        i = 0;
    } else if ((quality == 2) || (quality == 3)) {
        i = 1;
    } else if ((quality == 4) || (quality == 5)) {
        i = 2;
    } else {
        i = 3;
    }
    
    if (_audioQuality) {
        _audioQuality(i);
    }
}
- (int)startAudioMixing:(NSString*) filePath
               loopback:(BOOL) loopback
                replace:(BOOL) replace
                  cycle:(NSInteger) cycle
              didFinish:(void (^)(void))didFinish{
    self.didFinishPlayFileBlock = didFinish;
    return [_agoraRtcEngine startAudioMixing:filePath loopback:loopback replace:replace cycle:cycle];
}
- (void)rtcEngineLocalAudioMixingDidFinish:(AgoraRtcEngineKit *)engine{
      if (self.didFinishPlayFileBlock) self.didFinishPlayFileBlock();
}
- (int)stopAudioMixing{
    return [_agoraRtcEngine stopAudioMixing];
}
//- (int)pauseAudioMixing{
//     return [_agoraRtcEngine stopAudioMixing];
////    return [_agoraRtcEngine pauseAudioMixing];
//}
//- (int)resumeAudioMixing{
//    return 1;
////    return [_agoraRtcEngine resumeAudioMixing];
//}
//- (int)adjustAudioMixingVolume:(NSInteger) volume{
//        return 1;
////    return [_agoraRtcEngine adjustAudioMixingVolume:volume];
//}
//- (int)getAudioMixingDuration{
//        return 1;
////    return [_agoraRtcEngine getAudioMixingDuration];
//}
//- (int)getAudioMixingCurrentPosition{
//        return 1;
////    return [_agoraRtcEngine getAudioMixingCurrentPosition];
//}
//- (int)setAudioMixingPosition:(NSInteger) pos{
//        return 1;
////    return [_agoraRtcEngine setAudioMixingPosition:pos];
//}
//
//



@end
