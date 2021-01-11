//
//  FLXMPPManager.m
//  Transner
//
//  Created by VanRo on 16/9/1.
//  Copyright © 2016年 Transn. All rights reserved.
//

#import "XMPPManager.h"
#import "TransnSDK.h"
#import "XMPP.h"
#import "XMPPReconnect.h"
#import "XMPPStreamManagementMemoryStorage.h"
#import "XMPPRosterMemoryStorage.h"
#import "XMPPMessageArchiving.h"
#import "XMPPMessageArchivingCoreDataStorage.h"
#import <libxml/tree.h>

#import "XMPPAutoPing.h"
#import "TRMessage.h"
#import "XMPPMessage+XEP_0085.h"

#import "TransnSDK+Private.h"
#import "NSDate+TRExtension.h"
#import "TRTranslator.h"
#import "TRMessageStorage.h"

@interface XMPPManager ()

// 模块
@property (nonatomic, strong) XMPPReconnect *xmppReconnect;
@property (nonatomic, strong) XMPPAutoPing  *xmppAutoPing;

@property (nonatomic, copy)   NSString *myPassword;

@property (nonatomic, strong) XMPPStreamManagementMemoryStorage *storage;
@property (nonatomic, strong) XMPPStreamManagement              *xmppStreamManagement;

@property (nonatomic, strong) XMPPRoster                *xmppRoster;
@property (nonatomic, strong) XMPPRosterMemoryStorage   *xmppRosterMemoryStorage;

@property (nonatomic, strong) XMPPMessageArchiving                  *xmppMessageArchiving;
@property (nonatomic, strong) XMPPMessageArchivingCoreDataStorage   *xmppMessageArchivingCoreDataStorage;

@end

@implementation XMPPManager

static XMPPManager *_instance;

+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        _instance = [[XMPPManager alloc] init];
        //消息都是XMPP的，所以在这里设置最好
        [TRMessageStorage sharedStorage].messageStoreMode = TRMessageStoreDefault;
        [_instance setupStream];
    });
    
    return _instance;
}

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate) name:UIApplicationWillTerminateNotification object:nil];
    }
    
    return self;
}

#pragma mark -- strean setup

- (void)setupStream
{
    if (!_xmppStream) {
        _xmppStream = [[XMPPStream alloc] init];
        
        [self.xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
        [self.xmppStream setKeepAliveInterval:30];
        self.xmppStream.enableBackgroundingOnSocket = YES;
        
        // 接入断线重连模块
        _xmppReconnect = [[XMPPReconnect alloc] init];
        _xmppReconnect.reconnectTimerInterval = 10;
        [_xmppReconnect setAutoReconnect:YES];
        [_xmppReconnect activate:self.xmppStream];
        
        _xmppAutoPing = [[XMPPAutoPing alloc] init];
        [_xmppAutoPing activate:_xmppStream];
        [_xmppAutoPing addDelegate:self delegateQueue:dispatch_get_main_queue()];
        _xmppAutoPing.respondsToQueries = YES;
        _xmppAutoPing.targetJID = [XMPPJID jidWithString:_XMPP_HOST];
        _xmppAutoPing.pingInterval = 30;
        
        // 接入流管理模块
        _storage = [XMPPStreamManagementMemoryStorage new];
        _xmppStreamManagement = [[XMPPStreamManagement alloc] initWithStorage:_storage];
        _xmppStreamManagement.autoResume = YES;
        [_xmppStreamManagement addDelegate:self delegateQueue:dispatch_get_main_queue()];
        [_xmppStreamManagement activate:self.xmppStream];
        
        //        //接入好友模块
        //        _xmppRosterMemoryStorage = [[XMPPRosterMemoryStorage alloc] init];
        //        _xmppRoster = [[XMPPRoster alloc] initWithRosterStorage:_xmppRosterMemoryStorage];
        //        [_xmppRoster activate:self.xmppStream];
        //        [_xmppRoster addDelegate:self delegateQueue:dispatch_get_main_queue()];
        
        // 接入消息模块
        if ([TRMessageStorage sharedStorage].messageStoreMode == TRMessageStoreAll || [TRMessageStorage sharedStorage].messageStoreMode == TRMessageStoreXMPP) {
            _xmppMessageArchivingCoreDataStorage = [XMPPMessageArchivingCoreDataStorage sharedInstance];
            _xmppMessageArchiving = [[XMPPMessageArchiving alloc] initWithMessageArchivingStorage:_xmppMessageArchivingCoreDataStorage dispatchQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 9)];
            [_xmppMessageArchiving activate:self.xmppStream];
        }else{
        }
    }
}
-(void)activateStream{
    if (!_xmppMessageArchivingCoreDataStorage) {
        _xmppMessageArchivingCoreDataStorage = [XMPPMessageArchivingCoreDataStorage sharedInstance];
    }
    if (!_xmppMessageArchiving) {
        _xmppMessageArchiving = [[XMPPMessageArchiving alloc] initWithMessageArchivingStorage:_xmppMessageArchivingCoreDataStorage dispatchQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 9)];
        [_xmppMessageArchiving activate:self.xmppStream];
    }
    

}
-(void)deactivateStream{
    if (_xmppMessageArchiving) {
        [_xmppMessageArchiving deactivate];
        _xmppMessageArchiving = nil;
    }
    if (_xmppMessageArchivingCoreDataStorage) {
        _xmppMessageArchivingCoreDataStorage = nil;
    }
}

- (void)setXMPP_HOST:(NSString *)XMPP_HOST
{
    _XMPP_HOST = XMPP_HOST;
    _xmppAutoPing.targetJID = [XMPPJID jidWithString:_XMPP_HOST];
    [self.xmppStream setHostName:_XMPP_HOST];
}

- (void)setXMPP_PORT:(int)XMPP_PORT
{
    _XMPP_PORT = XMPP_PORT;
    [self.xmppStream setHostPort:_XMPP_PORT];
}

- (void)setXMPP_DOMAIN:(NSString *)XMPP_DOMAIN
{
    _XMPP_DOMAIN = XMPP_DOMAIN;
}

#pragma mark -- go onlie, offline

- (void)loginWithName:(NSString *)userName andPassword:(NSString *)password
{
    //    if ([self.xmppStream isAuthenticated]) {
    //        [self logOut];
    //    }
    _myJID = [XMPPJID jidWithUser:userName domain:_XMPP_DOMAIN resource:XMPP_Resource];
    self.myPassword = password;
    [self.xmppStream setMyJID:_myJID];
    NSError *error = nil;
    
    if (![_xmppStream connectWithTimeout:10 error:&error]) {}
}

- (void)logOut
{
    // 防止重新登录
    if (_myJID) {
        _myPassword = @"";
        _myJID = nil;
        //    [self goOffline];
        XMPPPresence    *p = [XMPPPresence presenceWithType:@"unavailable"];
        DDXMLNode       *status = [DDXMLElement elementWithName:@"status" stringValue:XMPP_OnlineState_unavailable];
        [p addChild:status];
        [[self xmppStream] sendElement:p];
        [_xmppStream disconnect];
//        [_xmppStream disconnectAfterSending];
    }
}

- (void)goOnline
{
    XMPPPresence    *p = [XMPPPresence presence];
    DDXMLNode       *status = [DDXMLElement elementWithName:@"status" stringValue:XMPP_OnlineState_online];
    DDXMLNode       *priority = [DDXMLElement elementWithName:@"priority" stringValue:@"9"];
    DDXMLNode       *show = [DDXMLElement elementWithName:@"show" stringValue:@"chat"];
    
    [p addChild:status];
    [p addChild:priority];
    [p addChild:show];
    [[self xmppStream] sendElement:p];
}

- (void)goOffline
{
    XMPPPresence    *p = [XMPPPresence presence];
    DDXMLNode       *status = [DDXMLElement elementWithName:@"status" stringValue:XMPP_OnlineState_offline];
    DDXMLNode       *priority = [DDXMLElement elementWithName:@"priority" stringValue:@"0"];
    DDXMLNode       *show = [DDXMLElement elementWithName:@"show" stringValue:@"away"];
    
    [p addChild:status];
    [p addChild:priority];
    [p addChild:show];
    
    [[self xmppStream] sendElement:p];
}

- (void)goBusyline
{
    XMPPPresence    *p = [XMPPPresence presence];
    DDXMLNode       *status = [DDXMLElement elementWithName:@"status" stringValue:XMPP_OnlineState_busyline];
    DDXMLNode       *priority = [DDXMLElement elementWithName:@"priority" stringValue:@"9"];
    DDXMLNode       *show = [DDXMLElement elementWithName:@"show" stringValue:@"dnd"];// away
    
    [p addChild:status];
    [p addChild:show];
    [p addChild:priority];
    [[self xmppStream] sendElement:p];
}

- (NSString *)getMyPresenceType
{
    XMPPPresence *presence = [_xmppStream myPresence];
    
    return presence.type;
}

- (NSString *)getUUID
{
    CFUUIDRef   puuid = CFUUIDCreate(nil);
    CFStringRef uuidString = CFUUIDCreateString(nil, puuid);
    NSString    *result = (NSString *)CFBridgingRelease(CFStringCreateCopy(NULL, uuidString));
    
    CFRelease(puuid);
    CFRelease(uuidString);
    return result;
}

- (XMPPMessage *)newMessageWithBody:(NSString *)body subject:(NSString *)subject to:(NSString *)userID flowdID:(NSString *)flowdID
{
    if (userID == nil) {
        userID = _myPassword;
        TRLog(@"toId == nil!!!!!!!!!!!!!!");
    }
    
    XMPPJID     *jid = [[XMPPJID jidWithUser:userID domain:_XMPP_DOMAIN resource:XMPP_Resource] bareJID];
    XMPPMessage *newMessage = [[XMPPMessage alloc] initWithType:@"chat" to:jid];
    
    if ([_myJID.user length] > 0) {
        [newMessage addAttributeWithName:@"from" stringValue:_myJID.full];
    }else{
          TRLog(@"userID == nil!!!!!!!!!!!!!!");
    }
    
    [newMessage addAttributeWithName:XMPP_Attribute_MessageID stringValue:[self getUUID]];
    
    if (body) {
        [newMessage addBody:body];
    }
    
    if (flowdID) {
        [newMessage addThread:flowdID];
    }
    
    if (subject) {
        [newMessage addSubject:subject];
    }
    
    return newMessage;
}

- (XMPPMessage *)cloudXmppMessage:(NSString *)body subject:(NSString *)subject from:(NSString *)fromId toId:(NSString *)toId flowId:(NSString *)flowId messageID:(NSString *)messageID
{
    XMPPMessage *newMessage = [[XMPPMessage alloc] initWithType:@"chat" to:nil];
    
    [newMessage addAttributeWithName:@"from" stringValue:fromId];
    [newMessage addAttributeWithName:@"to" stringValue:toId];
    [newMessage addAttributeWithName:XMPP_Attribute_MessageID stringValue:messageID];
    
    if (body) {
        [newMessage addBody:body];
    }
    
    if (flowId) {
        [newMessage addThread:flowId];
    }
    
    if (subject) {
        [newMessage addSubject:subject];
    }
    
    return newMessage;
}

- (void)sendComposingChatToUser:(NSString *)userID
{
    XMPPMessage *xmppMsg = [self newMessageWithBody:nil subject:@"ChatState" to:userID flowdID:nil];
    
    [xmppMsg addComposingChatState];
    [self sendMessage:xmppMsg];
}

- (void)sendPausedChatToUser:(NSString *)userID
{
    XMPPMessage *xmppMsg = [self newMessageWithBody:nil subject:@"ChatState" to:userID flowdID:nil];
    
    [xmppMsg addPausedChatState];
    [self sendMessage:xmppMsg];
}

- (void)sendMessage:(XMPPMessage *)xmppMsg
{
    if ([xmppMsg.to.user length] > 0) {
        [_xmppStream sendElement:xmppMsg];
    } else {
        TRLog(@"xmppMsg.to.user 为空,%@",xmppMsg);
    }
}

#pragma mark -- connect delegate

- (void)xmppStreamWillConnect:(XMPPStream *)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:IM_Connect_State_Change object:IM_Connect_State_WillConnect];
}

- (void)xmppStreamDidConnect:(XMPPStream *)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:IM_Connect_State_Change object:IM_Connect_State_DidConnect];
    
    NSError *error = nil;
    
    if (![[self xmppStream] authenticateWithPassword:_myPassword error:&error]) {
        TRLog(@"Error authenticating: %@", error);
    }
}

- (void)xmppStreamDidDisconnect:(XMPPStream *)sender withError:(NSError *)error
{
    [[NSNotificationCenter defaultCenter] postNotificationName:IM_Connect_State_Change object:IM_Connect_State_DidDisconnect];
    
    //    [APP_DELEGATE uploadErrorLog:@"XXMPP-DidDisconnect" expMsg:[error description] flowId:@""];
    
    @synchronized(_myPassword) {
        if (_myJID && ([_myPassword length] > 0) && ![sender isAuthenticated]) {
            double          delayInSeconds = 3;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
                [self loginWithName:self->_myJID.user andPassword:self->_myPassword];
            });
        }
    }
}

- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender
{
    [[TransnSDK shareManger] printLog:@"授权成功"];
    [[NSNotificationCenter defaultCenter] postNotificationName:IM_Connect_State_Change object:IM_Connect_State_DidAuthenticate];
    // 启用流管理
    [_xmppStreamManagement enableStreamManagementWithResumption:YES maxTimeout:0];
    if (self.accountDidAvilable) {
        self.accountDidAvilable();
    }
    self.accountDidAvilable = nil;
}

- (void)xmppStream:(XMPPStream *)sender didNotAuthenticate:(NSXMLElement *)error
{
    [[NSNotificationCenter defaultCenter] postNotificationName:IM_Connect_State_Change object:IM_Connect_State_DidNotAuthenticate];
    
    double          delayInSeconds = 3;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
        [[self xmppStream] authenticateWithPassword:self->_myPassword error:nil];
    });
}

- (BOOL)xmppStream:(XMPPStream *)sender didReceiveIQ:(XMPPIQ *)iq
{
    if (iq.isGetIQ) {
        // 解析iq 是ping类型则给openfier 响应一个IQ
        
        NSXMLElement *query = iq.childElement;
        
        if ([@"ping" isEqualToString:query.name]) {
            //服务器会在给定的时间内向客户端发送ping包（用来确认客户端用户是否在线）,当第二次发送bing包时，如果客户端无响应则会T用户下线
            
            NSXMLElement *ping = [NSXMLElement elementWithName:@"ping" xmlns:@"jabber:client"];
            
            NSXMLElement *iq = [NSXMLElement elementWithName:@"iq"];
            
            XMPPJID *myJID = self.xmppStream.myJID;
            
            [iq addAttributeWithName:@"from" stringValue:myJID.full];
            
            [iq addAttributeWithName:@"to" stringValue:myJID.domain];
            
            [iq addAttributeWithName:@"type" stringValue:@"get"];
            
            [iq addChild:ping];
            
            // 发送的iq可以不做任何的设置
            
            [self.xmppStream sendElement:iq];
        }
    }
    
    return YES;
}

#pragma mark -- XMPPMessage Delegate

- (void)xmppStream:(XMPPStream *)sender didReceiveError:(NSXMLElement *)error
{
    NSString *elementName = [error name];
    
    if ([elementName isEqualToString:@"stream:error"] || [elementName isEqualToString:@"error"]) {
        NSXMLElement *conflict = [error elementForName:@"conflict" xmlns:@"urn:ietf:params:xml:ns:xmpp-streams"];
        
        if (conflict && _accountOnKickOut) {
            _accountOnKickOut();
            TRLog(@"设备在其他地方上登录");
        }
    }
}

- (void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message
{
    if (_didReceiveMessage) {
        _didReceiveMessage(message);
    }
    
    //    TRLog(@"%s message %@",__func__,message);
}

- (void)xmppStream:(XMPPStream *)sender didSendMessage:(XMPPMessage *)message
{
    if (_didSendMessage) {
        _didSendMessage(message);
    }
    
    //    TRLog(@"%s message %@",__func__,message);
}

- (void)xmppStream:(XMPPStream *)sender didFailToSendMessage:(XMPPMessage *)message error:(NSError *)error
{
    if (_didFailToSendMessage) {
        _didFailToSendMessage(message);
    }
}

#pragma mark -- XMPP AutoPingDelegate

// ping XMPPAutoPingDelegate的委托方法:
- (void)xmppAutoPingDidSendPing:(XMPPAutoPing *)sender
{
    //    TRLog(@"- (void)xmppAutoPingDidSendPing:(XMPPAutoPing *)sender");
}

- (void)xmppAutoPingDidReceivePong:(XMPPAutoPing *)sender
{
    //    TRLog(@"- (void)xmppAutoPingDidReceivePong:(XMPPAutoPing *)sender");
}

- (void)xmppAutoPingDidTimeout:(XMPPAutoPing *)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:IM_Connect_State_Change object:IM_Connect_State_AutoPingDidTimeout];
}

#pragma mark -- Roster

- (void)xmppStream:(XMPPStream *)sender didReceivePresence:(XMPPPresence *)presence
{
    //    TRLog(@"%@",presence);
    // 对方上线或离线,更新状态
    // xmppRosterDidChange
}

- (void)xmppRosterDidChange:(XMPPRoster *)sender
{
    //    [[NSNotificationCenter defaultCenter] postNotificationName:@"RosterChanged" object:nil];
}

#pragma mark -- terminate

- (NSArray *)getMessageHistoryWithJID:(NSString *)userID
{
    XMPPJID                             *jid = [XMPPJID jidWithUser:userID domain:_XMPP_DOMAIN resource:XMPP_Resource];
    NSMutableArray                      *dataSource = [NSMutableArray array];
    XMPPMessageArchivingCoreDataStorage *storage = _xmppMessageArchivingCoreDataStorage;
    
    NSFetchRequest      *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:storage.messageEntityName inManagedObjectContext:storage.mainThreadManagedObjectContext];
    
    [fetchRequest setEntity:entity];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(bareJidStr = %@) && (streamBareJidStr = %@)", jid.bare, self.myJID.bare];
    [fetchRequest setPredicate:predicate];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timestamp"
        ascending                                                           :YES];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObjects:sortDescriptor, nil]];
//    NSLog(@"%@",fetchRequest);
    NSError *error = nil;
    NSArray *fetchedObjects = [storage.mainThreadManagedObjectContext executeFetchRequest:fetchRequest error:&error];
    
    if (fetchedObjects != nil) {
        TRTranslator *translatorMb = [TRTranslator managedObjectWithTranslatorId:userID];
        
        for (int i = 0; i < fetchedObjects.count; i++) {
            XMPPMessageArchiving_Message_CoreDataObject *recordMessage = fetchedObjects[i];
            
            if ([recordMessage.message.subject isEqualToString:XMPP_MessageType_Text]
                || [recordMessage.message.subject isEqualToString:XMPP_MessageType_Image] || [recordMessage.message.subject isEqualToString:XMPP_MessageType_Voice] || [recordMessage.message.subject isEqualToString:XMPP_MessageType_PaymentMessage] || [recordMessage.message.subject isEqualToString:XMPP_MessageType_RecommendMessage]) {
                TRMessage *tMsgs = [[TRMessage alloc] initWithMessage:recordMessage.message];
                tMsgs.sendState = TIMMessageSendStateSuccess;
                tMsgs.timestamp = recordMessage.timestamp;
//                tMsgs.translatorMb = translatorMb;
                [dataSource addObject:tMsgs];
            }
        }
    }
    
    return [dataSource copy];
}

- (void)deleteMessageHistoryWithJID:(NSString *)userID
{
    XMPPJID                             *jid = [XMPPJID jidWithUser:userID domain:_XMPP_DOMAIN resource:XMPP_Resource];
    XMPPMessageArchivingCoreDataStorage *storage = _xmppMessageArchivingCoreDataStorage;
    
    NSFetchRequest      *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:storage.messageEntityName inManagedObjectContext:storage.mainThreadManagedObjectContext];
    
    [fetchRequest setEntity:entity];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"bareJidStr = %@", jid.bare];
    [fetchRequest setPredicate:predicate];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timestamp"
        ascending                                                           :YES];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObjects:sortDescriptor, nil]];
    
    NSError *error = nil;
    NSArray *fetchedObjects = [storage.mainThreadManagedObjectContext executeFetchRequest:fetchRequest error:&error];
    
    for (XMPPMessageArchiving_Message_CoreDataObject *recordMessage in fetchedObjects) {
        [storage.mainThreadManagedObjectContext deleteObject:recordMessage];
    }
}

#pragma mark -- terminate

/**
 *  申请后台时间来清理下线的任务
 */
- (void)applicationWillTerminate
{
    UIApplication               *app = [UIApplication sharedApplication];
    UIBackgroundTaskIdentifier  taskId = 0;
    
    taskId = [app beginBackgroundTaskWithExpirationHandler:^(void) {
        [app endBackgroundTask:taskId];
    }];
    
    if (taskId == UIBackgroundTaskInvalid) {
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        // 只能在主线层执行
        [self->_xmppStream disconnectAfterSending];
    });
}

- (void)writeSendMessage:(XMPPMessage *)message
{
    if ([TRFileLog sharedManager].logEnabled) {
        NSString *fileName = [NSString stringWithFormat:@"%@_sendtMsgs_%@.txt",
                              [TransnSDK shareManger].myUserID, [NSDate currentDate:@"YYYYMMdd"]];
        NSString *fileContent = [NSString stringWithFormat:@"%@", message];
        [[TRFileLog sharedManager] writeContent:fileContent toFile:fileName];
    }
}

- (void)writeRecvMessage:(XMPPMessage *)message
{
    if ([TRFileLog sharedManager].logEnabled) {
        NSString *fileName = [NSString stringWithFormat:@"%@_recetMsgs_%@.txt",
                              [TransnSDK shareManger].myUserID, [NSDate currentDate:@"YYYYMMdd"]];
        NSString *fileContent = [NSString stringWithFormat:@"%@", message];
        [[TRFileLog sharedManager] writeContent:fileContent toFile:fileName];
    }
}

@end
