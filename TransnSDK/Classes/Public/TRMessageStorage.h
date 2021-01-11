/*!
 *   TRMessageStorage.h
 *   TransnSDK
 *
 *   Created by 姜政 on 2018/1/23.
 *   Copyright © 2018年 Transn. All rights reserved.
 *
 */

#import <Foundation/Foundation.h>

typedef NS_ENUM (NSInteger, TRMessageStoreMode) {
    /*!SDK内部方法，存到sqlite中去了*/
    TRMessageStoreDefault = 0,
    ///让xmpp协议自己保存到coredata中了
    TRMessageStoreXMPP = 1,
    ///全部存储,性能消耗会大一倍
    TRMessageStoreAll = 2,
};
@interface TRMessageStorage : NSObject

+ (instancetype)sharedStorage;


///消息存储方法,默认为TRMessageStoreDefault
@property (nonatomic, assign) TRMessageStoreMode messageStoreMode;
@end
