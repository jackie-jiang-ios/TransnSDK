//
//  NSManagedObject+TExtension.m
//  TransnSDK
//
//  Created by 姜政 on 2018/1/4.
//  Copyright © 2018年 Transn. All rights reserved.
//

#import "NSManagedObject+TExtension.h"
//#import "CoreDataEnvirHeader.h"
#import <MagicalRecord/MagicalRecord.h>
#import "TROrderManger+Private.h"
#import "TransnSDK+Private.h"

@implementation NSManagedObject (TExtension)

#pragma mark TranslatorManagedObject
+ (TranslatorManagedObject *)managedObjectWithTranslatorId:(NSString *)translatorId
{
    NSArray *translatorList = [TranslatorManagedObject MR_findAllWithPredicate:[NSPredicate predicateWithFormat:@"translatorId =  %@",translatorId]];
    TranslatorManagedObject *tr = translatorList.firstObject;
    
    return tr;
}

+ (void)insertItemWithDict:(NSDictionary *)dict
{
    dispatch_async(dispatch_get_main_queue(), ^{
//        NSArray *array = [TranslatorManagedObject itemsWithFormat:@"translatorId = %@", dict[@"userid"]];
        NSArray *array = [TranslatorManagedObject MR_findAllWithPredicate:[NSPredicate predicateWithFormat:@"translatorId = %@",dict[@"userid"]]];
        if (array.count) {
            //有就更新
            TranslatorManagedObject *item = array.firstObject;
            
            item.translatorName = [dict objectForKey:@"userName"];
            item.translatorIcon = [dict objectForKey:@"image"];
            item.translatorId = [dict objectForKey:@"userid"];
            item.transerInfo = [dict objectForKey:@"translatorRemark"];
//            [[CoreDataEnvir instance] saveDataBase];
            [item.managedObjectContext MR_saveOnlySelfAndWait];
        } else {
//            [TranslatorManagedObject insertItemWithFillingBlock:^(TranslatorManagedObject *item) {
//                item.translatorName = [dict objectForKey:@"userName"];
//                item.translatorIcon = [dict objectForKey:@"image"];
//                item.translatorId = [dict objectForKey:@"userid"];
//                item.transerInfo = [dict objectForKey:@"translatorRemark"];
//            }];
            TranslatorManagedObject *item = [TranslatorManagedObject MR_createEntity];
            item.translatorName = [dict objectForKey:@"userName"];
            item.translatorIcon = [dict objectForKey:@"image"];
            item.translatorId = [dict objectForKey:@"userid"];
            item.transerInfo = [dict objectForKey:@"translatorRemark"];
            [item.managedObjectContext MR_saveOnlySelfAndWait];
        }
    });
}

+ (void)updateTranslator:(TRTranslator *)translator
{
    dispatch_async(dispatch_get_main_queue(), ^{
//        NSArray *array = [TranslatorManagedObject itemsWithFormat:@"translatorId = %@", translator.translatorId];
        NSArray *array = [TranslatorManagedObject MR_findAllWithPredicate:[NSPredicate predicateWithFormat:@"translatorId = %@",translator.translatorId]];
        if (array.count) {
            //通过历史订单进来，不更新
        } else {
            TranslatorManagedObject *item = [TranslatorManagedObject MR_createEntity];
            item.translatorName = translator.translatorName;
            item.translatorIcon = translator.translatorIcon;
            item.translatorId = translator.translatorId;
            item.transerInfo = translator.transerInfo;
            [item.managedObjectContext MR_saveOnlySelfAndWait];

//            [TranslatorManagedObject insertItemWithFillingBlock:^(TranslatorManagedObject *item) {
//                item.translatorName = translator.translatorName;
//                item.translatorIcon = translator.translatorIcon;
//                item.translatorId = translator.translatorId;
//                item.transerInfo = translator.transerInfo;
//            }];
//            [[CoreDataEnvir instance] saveDataBase];
        }
    });
}


#pragma mark TRMessage


+ (void)selectMessagesByFlowId:(NSString *)flowId result:(void (^)(NSArray <TRMessage *> *messages))block
{
    if (block) {
        dispatch_async(dispatch_get_main_queue(), ^{
//            NSArray <TRMessageManagedObject *> *messages = [TRMessageManagedObject itemsWithFormat:@"flowId = %@", flowId];
            NSArray <TRMessageManagedObject *> *messages  = [TRMessageManagedObject  MR_findAllWithPredicate:[NSPredicate predicateWithFormat:@"flowId = %@",flowId]];
            NSMutableArray *list = [NSMutableArray arrayWithCapacity:messages.count];

            for (NSInteger i = 0; i < messages.count; i++) {
                TRMessageManagedObject *oneMsg = messages[i];
                NSData *exMessageData = oneMsg.exMessage;
                TRMessage *msg = [NSKeyedUnarchiver unarchiveObjectWithData:exMessageData];
                if (msg.sendState == TIMMessageSendStateSending) {
                    msg.sendState = TIMMessageSendStatefail;
                }

                [list addObject:msg];
            }

            block(list);
        });
    }
}

+ (void)selectMessagesByUserId:(NSString *)userId translatorId:(NSString *)translatorId result:(void (^)(NSArray <TRMessage *> *messages))block
{
    if (block) {
        dispatch_async(dispatch_get_main_queue(), ^{
//            NSArray <TRMessageManagedObject *> *messages = [TRMessageManagedObject itemsWithFormat:@"userId = %@ && translatorId = %@", userId, translatorId];
            NSArray <TRMessageManagedObject *> *messages  = [TRMessageManagedObject MR_findAllWithPredicate:[NSPredicate predicateWithFormat:@"userId = %@ && translatorId = %@", userId, translatorId]];

            NSMutableArray *list = [NSMutableArray arrayWithCapacity:messages.count];

            for (NSInteger i = 0; i < messages.count; i++) {
                TRMessageManagedObject *oneMsg = messages[i];
                NSData *exMessageData = oneMsg.exMessage;
                TRMessage *msg = [NSKeyedUnarchiver unarchiveObjectWithData:exMessageData];
                if (msg.sendState == TIMMessageSendStateSending) {
                    msg.sendState = TIMMessageSendStatefail;
                }
                [list addObject:msg];
            }

            block(list);
        });
    }
}
+(BOOL)canSendMessage{
    //接单前发送消息，不发送
    if (![TransnSDK shareManger].orderManger.currentOrder.isConnected) {
        return NO;
    }else if(![TransnSDK shareManger].orderManger.currentOrder.translator||[TransnSDK shareManger].orderManger.currentOrder.translator.translatorId.length ==0){
        return NO;
    }
    return YES;
}
//
+ (void)insertMessage:(TRMessage *)message flowId:(NSString *)flowId userId:(NSString *)userId
{
    if (message.isMyself&&![self canSendMessage]) {
        return;
    }
    if (message.isMyself) {
        [[TransnSDK shareManger] printMessageLog:[NSString stringWithFormat:@"%s",__func__]];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        TRMessageManagedObject *item = [TRMessageManagedObject MR_createEntity];
        item.messageId = message.messageID;
       if (message.translatorMb.translatorId) {
           item.translatorId = message.translatorMb.translatorId;
       } else {
           item.translatorId = [TransnSDK shareManger].orderManger.currentOrder.translator.translatorId;
       }
       item.flowId = flowId;
       item.userId = userId;
       item.createTime = message.timestamp;
       item.exMessage = [NSKeyedArchiver archivedDataWithRootObject:message];
       [item.managedObjectContext MR_saveOnlySelfAndWait];
        
//        [TRMessageManagedObject insertItemWithFillingBlock:^(TRMessageManagedObject *item) {
//            item.messageId = message.messageID;
//            if (message.translatorMb.translatorId) {
//                item.translatorId = message.translatorMb.translatorId;
//            } else {
//                item.translatorId = [TransnSDK shareManger].orderManger.currentOrder.translator.translatorId;
//            }
//            item.flowId = flowId;
//            item.userId = userId;
//            item.createTime = message.timestamp;
//            item.exMessage = [NSKeyedArchiver archivedDataWithRootObject:message];
//        }];
//        [[CoreDataEnvir instance] saveDataBase];
    });
}



+ (void)updateMessage:(TRMessage *)msg state:(TIMMessageSendState)state time:(int)time flowId:(NSString *)flowId userId:(NSString *)userId
{

    dispatch_async(dispatch_get_main_queue(), ^{
//        NSArray *array = [TRMessageManagedObject itemsWithFormat:@"messageId = %@", msg.messageID];
        NSArray *array   =[TRMessageManagedObject MR_findAllWithPredicate:[NSPredicate predicateWithFormat:@"messageId = %@",msg.messageID]];
        if (array.count) {
            //有就更新
            TRMessageManagedObject *item = array.firstObject;
            NSData *exMessageData = item.exMessage;
            TRMessage *message = [NSKeyedUnarchiver unarchiveObjectWithData:exMessageData];
            item.messageId = message.messageID;
            message.sendState = state;//主要是更新这个
            if (message.messageType == TIMMessageTypeImage) {
                //此方法会修改XMPP的body
                 message.imageUrl = msg.imageUrl;//图片上传成功时，主要是更新这个
            }else if(message.messageType == TIMMessageTypeVocie){
                //此方法会修改XMPP的body
                 message.voiceUrl = msg.voiceUrl;//语音文件上传成功时,主要是更新这个
            }else if(message.messageType == TIMMessageTypePaymentMessage){
                //理论上SDK都是提供给客户端使用，不会出现PaymentMessage走这个方法
                if (msg.paymentMessageType==PaymentMsgTypeText2Voice||msg.paymentMessageType==PaymentMsgTypeImage2Voice||msg.paymentMessageType==PaymentMsgTypeVoice2Voice) {
                    //此方法会修改XMPP的body
                    message.voiceUrl = msg.voiceUrl;//语音文件上传成功时,主要是更新这个
                }
            }
            if (message.translatorMb.translatorId) {
                item.translatorId = message.translatorMb.translatorId;
            } else {
                item.translatorId = [TransnSDK shareManger].orderManger.currentOrder.translator.translatorId;
            }
            
            if (!message.timestamp) {
                message.timestamp = [NSDate date];
            }
            item.createTime = message.timestamp;
            item.exMessage = [NSKeyedArchiver archivedDataWithRootObject:message];
            [item.managedObjectContext MR_saveOnlySelfAndWait];
        } else {
            // 没有就再存储一次
            if (time > 0) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self updateMessage:msg state:state time:time - 1 flowId:flowId userId:userId];
                });
            } else {
                if (msg.isMyself&&![self canSendMessage]) {
                    return;
                }
                [[TransnSDK shareManger] printMessageLog:[NSString stringWithFormat:@"%s",__func__]];
                //可以存就改它的状态，不能存，就不要改了,免得影响留言消息
                msg.sendState = state;
                [self insertMessage:msg flowId:flowId userId:userId];
            }
        }
    });
}

@end
