//
//  NSDate+TRExtension.m
//  TransnSDK
//
//  Created by 姜政 on 2017/8/17.
//  Copyright © 2017年 Transn. All rights reserved.
//

#import "NSDate+TRExtension.h"

@implementation NSDate (TRExtension)
// SingletonM(Date)

+ (NSString *)currentDate:(NSString *)formatterString
{
    //    [dateFormatter setDateFormat:@"dd.MM.YY HH:mm:ss"];
    NSDate          *currDate = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
    
    [dateFormatter setDateFormat:formatterString];
    NSString *dateString = [dateFormatter stringFromDate:currDate];
    return dateString;
}

@end
