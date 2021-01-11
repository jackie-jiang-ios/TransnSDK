/*!
 *   TRTranslator.h
 *   TransnSDK
 *
 *   Created by 姜政 on 2017/11/19.
 *   Copyright © 2018年 Transn. All rights reserved.
 *
 */

#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN

@interface TRTranslator : NSObject

/*!
 *   @result 目前不会实时更新
 *   @abstract   译员昵称
 */
@property (nullable, nonatomic, copy) NSString *translatorName;

/*!
 *   @result 目前不会实时更新，没有就是nil
 *   @abstract   译员简介
 */
@property (nullable, nonatomic, copy) NSString *transerInfo;

/*!
 *   @result 不变的，32位字符串
 *   @abstract  译员ID
 */
@property (nullable, nonatomic, copy) NSString *translatorId;

/*!
 *   @result 目前不会实时更新
 *   @abstract   译员头像
 */
@property (nullable, nonatomic, copy) NSString *translatorIcon;

/*!
 *   @method  通过译员ID获得译员对象
 *
 *   @param translatorId 译员ID
 *   @return 译员model
 */
+ (TRTranslator *)managedObjectWithTranslatorId:(NSString *)translatorId;

/*!
 *   @method  插入译员信息
 *
 *   @param dict 译员信息集合
 */
+ (void)insertItemWithDict:(NSDictionary *_Nullable)dict;
@end
NS_ASSUME_NONNULL_END
