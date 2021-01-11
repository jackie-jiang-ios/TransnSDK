//
//  TRAppDelegate.m
//  TransnSDK
//
//  Created by 13036101641@163.com on 08/04/2020.
//  Copyright (c) 2020 13036101641@163.com. All rights reserved.
//

#import "TRAppDelegate.h"
#import <TransnSDK/TransnSDK.h>

@implementation TRAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    //1.注册
    [TransnSDK registerAppKey:@"7D1060188E4F8DEA1841CCEB50401A83" appSecret:@"fa5c5c59ab531efe7f1fb1e9eef67da6"  environment:TransnEnvironmentProduct];

    //login
    [[TransnSDK shareManger] loginWithUserId:@"13036101641" completetion:^(NSError *error) {
        [self checkTrs];
    }];

   
    return YES;
}
-(void)checkTrs{
    [[TransnSDK shareManger] requestRecommendTranslator:@"1" destLangId:@"2" completetion:^(NSArray <TRTranslator *> *translators, NSError *error) {
        if (error) {

        } else {
            if (translators.count) {
                BOOL needOnlineStatus = YES;

                if (needOnlineStatus) {
                    [self getFormList:translators OnLineTrs:^(NSArray *onlineTrs) {

                    }];
                } else {

                }
            }
        }
    }];
}

- (void)getFormList:(NSArray <TRTranslator *> *)list OnLineTrs:(void (^) (NSArray *onlineTrs))block
{
    NSMutableArray *trIds = [NSMutableArray arrayWithCapacity:list.count];
    
    for (NSInteger i = 0; i < list.count; i++) {
        TRTranslator *translator = list[i];
        [trIds addObject:translator.translatorId];
    }
    
    NSString *trIdStr = [trIds componentsJoinedByString:@","];
    [[TransnSDK   shareManger] getTranslatorsStatus:trIdStr result:^(NSArray *results) {
        NSMutableArray *onLineTrs = [NSMutableArray arrayWithCapacity:results.count];
        
        for (NSInteger i = 0; i < results.count; i++) {
            NSDictionary *onLineTrDic = results[i];
            
            if ([[onLineTrDic objectForKey:@"status"] isEqualToString:@"TR_ONLINE"]) {
                [onLineTrs addObject:onLineTrDic];
            }
        }
        
        if (block) {
            block(onLineTrs);
        }
    }];
}
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
