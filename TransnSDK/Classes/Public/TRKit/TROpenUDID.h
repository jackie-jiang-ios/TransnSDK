//
//  TROpenUDID.h
//  TransnSDK
//
//  Created by 姜政 on 2017/8/17.
//  Copyright © 2017年 Transn. All rights reserved.
//

#import <Foundation/Foundation.h>

//
// Usage:
//    #include "TROpenUDID.h"
//    NSString* openUDID = [TROpenUDID value];
//

#define kOpenUDIDErrorNone          0
#define kOpenUDIDErrorOptedOut      1
#define kOpenUDIDErrorCompromised   2

@interface TROpenUDID : NSObject {}
+ (NSString *)value;
+ (NSString *)valueWithError:(NSError **)error;
+ (void)setOptOut:(BOOL)optOutValue;

@end
