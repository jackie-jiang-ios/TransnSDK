/*!
 *   NSManagedObject+TExtension.h
 *   TransnSDK
 *
 *   Created by 姜政 on 2018/1/4.
 *   Copyright © 2018年 Transn. All rights reserved.
 */

#import <CoreData/CoreData.h>
#import "TranslatorManagedObject+CoreDataClass.h"
#import "TRMessageManagedObject+CoreDataClass.h"
#import "TRTranslator.h"
#import "TRMessage.h"
NS_ASSUME_NONNULL_BEGIN


@interface NSManagedObject (TExtension)

#pragma mark TranslatorManagedObject
/*!
@method  通过译员ID得到TranslatorManagedObject对象
@abstract TranslatorManagedObject是coredata对象
@discussion 这里可以具体写写这个方法如何使用，注意点之类的。如果你是设计一个抽象类或者一个共通类给给其他类继承的话，建议在这里具体描述一下怎样使用这个方法。
@param translatorId 译员ID
@result 返回译员的NSManagedObject对象
*/
+ (TranslatorManagedObject *_Nullable)managedObjectWithTranslatorId:(NSString *_Nullable)translatorId;

/*!
 @brief 插入一个译员对象到数据库
 @param dict 译员的信息
 */
+ (void)insertItemWithDict:(NSDictionary *_Nullable)dict;


/*!
 @brief 更coredata中的新译员信息

 @param translator 译员对象
 */
+ (void)updateTranslator:(TRTranslator *)translator;

#pragma mark TRMessage

/*!
 @brief 获取某一订单的聊天记录
 @param flowId 订单ID
 @param block 消息数组
 */
+ (void)selectMessagesByFlowId:(NSString *)flowId result:(void (^)(NSArray <TRMessage *> *messages))block;

/*!
 @brief 获取sdk的用户ID和译员ID查询消息
 @param userId 用户ID
 @param translatorId 译员ID
 @param block 消息数组
 */
+ (void)selectMessagesByUserId:(NSString *)userId translatorId:(NSString *)translatorId result:(void (^)(NSArray <TRMessage *> *messages))block;


/*!
 @brief 更新message的对象
 @discussion   外部数据也是用此方法
 @param message 消息对象
 @param state 消息状态
 @param time 重复次数 一般为5
 @param flowId 当前订单ID
 @param userId 当前用户ID
 */
+ (void)updateMessage:(TRMessage *)message state:(TIMMessageSendState)state time:(int)time flowId:(NSString *)flowId userId:(NSString *)userId;

@end
NS_ASSUME_NONNULL_END
