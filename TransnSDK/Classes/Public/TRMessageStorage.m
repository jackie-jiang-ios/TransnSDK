//
//  TRMessageStorage.m
//  TransnSDK
//
//  Created by 姜政 on 2018/1/23.
//  Copyright © 2018年 Transn. All rights reserved.
//

#import "TRMessageStorage.h"
#import "XMPPManager.h"
@implementation TRMessageStorage


+ (instancetype)sharedStorage{
    static id _instace = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instace = [[self alloc] init];
    });
    return _instace; 
}
-(void)setMessageStoreMode:(TRMessageStoreMode)messageStoreMode{
    if (_messageStoreMode == messageStoreMode) {
        
    }else{
        _messageStoreMode = messageStoreMode;
        if (messageStoreMode== TRMessageStoreAll || messageStoreMode== TRMessageStoreXMPP) {
            [[XMPPManager sharedInstance] activateStream];
        }else{
            [[XMPPManager sharedInstance] deactivateStream];
        }
    }
}
@end
