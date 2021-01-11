/*!
 *   TRNotification.m
 *   TransnSDK
 *
 *   Created by 姜政 on 2018/3/3
 *   Copyright © 2018年 Transn. All rights reserved.
 */

#import "TRNotification.h"

@implementation TRNotification
+ (instancetype)sharedManager{
    static id _instace = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instace = [[self alloc] init];
    });
    return _instace;
}

-(NSString *)notificationNameForTypeString:(NSString *)typeString{
    if ([typeString isEqualToString:ReCallUser]) {
        return @"NOTIFICATION_ReCallUser";
    }else if([typeString isEqualToString:CollectTransOnLine]){
        return [NSString stringWithFormat:@"NOTIFICATION_%@",typeString];
    }else if([typeString isEqualToString:HwStatusMsg]){
        return @"NOTIFICATION_UpdateDeviceInfo";
    }else if([typeString isEqualToString:BookOrderReceived]){
         return [NSString stringWithFormat:@"NOTIFICATION_%@",typeString];
    }else if([typeString isEqualToString:BookOrderStartRemind]){
         return [NSString stringWithFormat:@"NOTIFICATION_%@",typeString];
    }else if([typeString isEqualToString:BookOrderTimeout]){
         return [NSString stringWithFormat:@"NOTIFICATION_%@",typeString];
    }else if([typeString isEqualToString:BookOrderUserMiss]){
         return [NSString stringWithFormat:@"NOTIFICATION_%@",typeString];
    }else if([typeString isEqualToString:BookOrderTrDutyCancel]){
        return [NSString stringWithFormat:@"NOTIFICATION_%@",typeString];
    }else if([typeString isEqualToString:BookOrderTrNoDutyCancel]){
        return [NSString stringWithFormat:@"NOTIFICATION_%@",typeString];
    }else if([typeString isEqualToString:BookOrderTrMiss]){
         return [NSString stringWithFormat:@"NOTIFICATION_%@",typeString];
    }else if([typeString isEqualToString:MicroOrderLeaveMsg]){
        return [NSString stringWithFormat:@"NOTIFICATION_%@",typeString];
    }
    return typeString;
}

-(void)postNotificationName:(NSString *)name object:(id)object userInfo:(NSDictionary *)info{
    [[NSNotificationCenter defaultCenter] postNotificationName:[self notificationNameForTypeString:name] object:object userInfo:info];
}

@end
