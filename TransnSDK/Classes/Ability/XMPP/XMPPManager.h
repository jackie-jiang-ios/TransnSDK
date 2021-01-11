//
//  FLXMPPManager.h
//  Transner
//
//  Created by VanRo on 16/9/1.
//  Copyright © 2016年 Transn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XMPPMessage.h"
#import "XMPPStreamManagement.h"
#import "XMPPMessage+XEP_0085.h"

// static NSString *const XMPP_HOST = @"118.193.25.18";
// static NSString *const XMPP_DOMAIN = @"openfire.xjp";
static NSString *const XMPP_Resource = @"CORE";

// static const int XMPP_PORT = 5222;
static NSString *const  XMPP_MessageType_Image = @"Image";
static NSString *const  XMPP_MessageType_Text = @"Text";
static NSString *const  XMPP_MessageType_Voice = @"Voice";
static NSString *const  XMPP_MessageType_Tip = @"TipsMessage";
static NSString *const  XMPP_MessageType_Notification = @"Notification";
static NSString *const  XMPP_MessageType_Info = @"Infomation";
///带有原文和译文的按条付费消息
static NSString *const  XMPP_MessageType_PaymentMessage = @"PaymentMessage";
static NSString *const  XMPP_MessageType_RecommendMessage = @"RecommendMessage";
// available
static NSString *const  XMPP_OnlineState_offline = @"offline";          // unavailable
static NSString *const  XMPP_OnlineState_busyline = @"busy";
static NSString *const  XMPP_OnlineState_online = @"online";            // unavailable
static NSString *const  XMPP_OnlineState_unavailable = @"unavailable";  // unavailable

static NSString *const XMPP_Attribute_MessageID = @"id";

@interface XMPPManager : NSObject

@property (nonatomic, strong) XMPPJID       *myJID;
@property (nonatomic, strong) XMPPStream    *xmppStream;

@property (nonatomic, copy) NSString    *XMPP_HOST;
@property (nonatomic, copy) NSString    *XMPP_DOMAIN;
@property (nonatomic, assign) int       XMPP_PORT;

@property(nonatomic, copy) void (^didReceiveMessage)(XMPPMessage *message);
@property(nonatomic, copy) void (^didSendMessage)(XMPPMessage *message);
@property(nonatomic, copy) void (^didFailToSendMessage)(XMPPMessage *message);

///账号在其他地方登陆时候回触发
@property (nonatomic, copy) void (^accountOnKickOut)(void);
///账号授权成功
@property (nonatomic, copy) void (^accountDidAvilable)(void);
+ (instancetype)sharedInstance;

- (void)loginWithName:(NSString *)userName andPassword:(NSString *)password;

///退出登录
- (void)logOut;
///上线
- (void)goOnline;
///下线
- (void)goOffline;
///忙碌
- (void)goBusyline;

- (NSString *)getMyPresenceType;

- (XMPPMessage *)newMessageWithBody:(NSString *)body subject:(NSString *)subject to:(NSString *)userID flowdID:(NSString *)flowdID;

- (XMPPMessage *)cloudXmppMessage:(NSString *)body subject:(NSString *)subject from:(NSString *)fromId toId:(NSString *)toId flowId:(NSString *)flowId messageID:(NSString *)messageID;

- (void)sendMessage:(XMPPMessage *)xmppMsg;

// 获取历史消息
- (NSArray *)getMessageHistoryWithJID:(NSString *)userID;

//删除历史消息
- (void)deleteMessageHistoryWithJID:(NSString *)userID;

- (NSString *)getUUID;

- (void)sendComposingChatToUser:(NSString *)userID;

- (void)sendPausedChatToUser:(NSString *)userID;

//上传日志用
- (void)writeSendMessage:(XMPPMessage *)message;
- (void)writeRecvMessage:(XMPPMessage *)message;

-(void)activateStream;
-(void)deactivateStream;
@end
