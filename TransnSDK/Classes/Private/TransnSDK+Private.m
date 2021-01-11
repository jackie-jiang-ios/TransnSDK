//
//  TransnSDK+Private.m
//  TransnSDK
//
//  Created by Fan Lv on 16/10/27.
//  Copyright © 2016年 Transn. All rights reserved.
//

#import "TransnSDK+Private.h"
#import "TRBaseModel.h"
#import "XMPPManager.h"
#import "TRNetWork.h"
#import "TRPrivateConstants.h"
#import <objc/runtime.h>
#import "NSDate+TRExtension.h"

NSString *const countryIdKey = @"countryIdKey";
NSString *const twiiloTokenKey = @"twiiloTokenKey";
NSString *const qiNiuUploadImageUrlKey = @"qiNiuUploadImageUrlKey";
NSString *const qiNiuTokenKey = @"qiNiuTokenKey";
NSString *const qiNiuBaseUrlKey = @"qiNiuBaseUrlKey";
NSString *const timeToGetQiNiuTokenKey = @"timeToGetQiNiuTokenKey";
NSString *const xmppAutoLoginOutTimekey = @"xmppAutoLoginOutTimeKey";
NSString *const userIPKey = @"userIPKey";
NSString *const coreServerIpKey = @"coreServerIpKey";
NSString *const clientIDKey = @"clientIDKey";
NSString *const serverUtcTimestampDvalueKey = @"serverUtcTimestampDvalueKey";
NSString *const isLoginSDKKey = @"isLoginSDKKey";
@implementation TransnSDK (Private)
- (void)setCountryId:(NSString *)countryId
{
    objc_setAssociatedObject(self, &countryIdKey, countryId, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSString *)countryId
{
    return objc_getAssociatedObject(self, &countryIdKey);
}

- (void)setTwiiloToken:(NSString *)twiiloToken
{
    objc_setAssociatedObject(self, &twiiloTokenKey, twiiloToken, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSString *)twiiloToken
{
    return objc_getAssociatedObject(self, &twiiloTokenKey);
}

- (void)setQiNiuUploadImageUrl:(NSString *)qiNiuUploadImageUrl
{
    objc_setAssociatedObject(self, &qiNiuUploadImageUrlKey, qiNiuUploadImageUrl, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSString *)qiNiuUploadImageUrl
{
    return objc_getAssociatedObject(self, &qiNiuUploadImageUrlKey);
}

- (void)setQiNiuToken:(NSString *)qiNiuToken
{
    objc_setAssociatedObject(self, &qiNiuTokenKey, qiNiuToken, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSString *)qiNiuToken
{
    return objc_getAssociatedObject(self, &qiNiuTokenKey);
}

- (void)setQiNiuBaseUrl:(NSString *)qiNiuBaseUrl
{
    objc_setAssociatedObject(self, &qiNiuBaseUrlKey, qiNiuBaseUrl, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSString *)qiNiuBaseUrl
{
    return objc_getAssociatedObject(self, &qiNiuBaseUrlKey);
}


- (void)setTimeToGetQiNiuToken:(NSDate *)timeToGetQiNiuToken
{
    objc_setAssociatedObject(self, &timeToGetQiNiuTokenKey, timeToGetQiNiuToken, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSDate *)timeToGetQiNiuToken
{
    return objc_getAssociatedObject(self, &timeToGetQiNiuTokenKey);
}

- (void)setXmppAutoLoginOutTime:(NSNumber *)xmppAutoLoginOutTime
{
    objc_setAssociatedObject(self, &xmppAutoLoginOutTimekey, xmppAutoLoginOutTime, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSNumber *)xmppAutoLoginOutTime
{
    return objc_getAssociatedObject(self, &xmppAutoLoginOutTimekey);
}

- (void)setServerUtcTimestampDvalue:(NSNumber *)serverUtcTimestampDvalue
{
    objc_setAssociatedObject(self, &serverUtcTimestampDvalueKey,serverUtcTimestampDvalue, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSNumber *)serverUtcTimestampDvalue
{
    return objc_getAssociatedObject(self, &serverUtcTimestampDvalueKey);
}

- (void)setUserIP:(NSString *)userIP
{
    objc_setAssociatedObject(self, &userIPKey, userIP, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSString *)userIP
{
    return objc_getAssociatedObject(self, &userIPKey);
}

- (void)setCoreServerIp:(NSString *)coreServerIp
{
    objc_setAssociatedObject(self, &coreServerIpKey, coreServerIp, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSString *)coreServerIp
{
    return objc_getAssociatedObject(self, &coreServerIpKey);
}

- (void)setClientID:(NSString *)clientID
{
    objc_setAssociatedObject(self, &clientIDKey, clientID, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSString *)clientID
{
    return objc_getAssociatedObject(self, &clientIDKey);
}
-(void)setIsLoginSDK:(BOOL)isLoginSDK{
    objc_setAssociatedObject(self, &isLoginSDKKey, @(isLoginSDK), OBJC_ASSOCIATION_COPY_NONATOMIC);
}
-(BOOL)isLoginSDK{
    return [objc_getAssociatedObject(self, &isLoginSDKKey) boolValue];
}

- (void)setMyOnlineState:(OnlineState)myOnlineState
{
    if (myOnlineState == OnlineStateOnLine) {// 在线
        [[XMPPManager sharedInstance] goOnline];
    } else if (myOnlineState == OnlineStateOffLine) {// 离线
        [[XMPPManager sharedInstance] goOffline];
    } else if (myOnlineState == OnlineStateBusy) {// 忙碌
        [[XMPPManager sharedInstance] goBusyline];
    }
}

- (OnlineState)myOnlineState
{
    NSString *pType = [[XMPPManager sharedInstance] getMyPresenceType];
    
    if (pType == XMPP_OnlineState_offline) {
        return OnlineStateOffLine;
    } else if (pType == XMPP_OnlineState_busyline) {
        return OnlineStateBusy;
    } else {
        return OnlineStateOnLine;
    }
}

- (NSError *)checkAppIDAndAppSecretAvaliable
{
    NSString    *appKey = [TRNetWork sharedManager].appKey;
    NSString    *appSecret = [TRNetWork sharedManager].appSecret;
    
    if (([appKey length] == 0) || ([appSecret length] == 0)) {
        TRLog(@"appID和appSecret不能为空，请先调用注册接口");
        NSDictionary    *userInfo = [NSDictionary dictionaryWithObject:@"appID和appSecret不能为空" forKey:NSLocalizedDescriptionKey];
        NSError         *aError = [NSError errorWithDomain:@"" code:60004 userInfo:userInfo];
        return aError;
    }
    
    return nil;
}

- (void)printLog:(NSString *)toast
{
    if ([TRFileLog sharedManager].logEnabled) {
        TRLog(@"TrasnsnSDK内部打印:---%@", toast);
        [[TRFileLog sharedManager] writeToast:toast];
    }
}
- (void)printMessageLog:(NSString *)toast{
    if ([TRFileLog sharedManager].logAllEnabled) {
        TRLog(@"TrasnsnSDK内部打印:---%@", toast);
        [[TRFileLog sharedManager] writeToast:toast];
    }
}
- (void)writeToast:(NSString *)toast{
    if ([TRFileLog sharedManager].logEnabled) {
        [[TRFileLog sharedManager] writeToast:toast];
    }
}

#pragma mark - 上传错误日志
- (void)uploadErrorLog:(NSString *)expTitle expMsg:(NSString *)expContent
{
    [self uploadErrorLog:expTitle expMsg:expContent flowId:@""];
}

- (void)uploadErrorLog:(NSString *)expTitle expMsg:(NSString *)expContent flowId:(NSString *)flowId
{
    if ([expTitle length] == 0) {
        expTitle = @"nil";
    }
    
    if ([expContent length] == 0) {
        expContent = @"nil";
    }
    
    if ([flowId length] == 0) {
        flowId = @"nil";
    }
    
    [[TRFileLog sharedManager] writeErrorLog:expTitle expMsg:expContent flowId:flowId];
    
    NSString        *ipExcontent = [NSString stringWithFormat:@"%@-[%@]", self.userIP, expContent];
    NSDictionary    *sendDic = TRDicWithOAndK(expTitle, @"expTitle", ipExcontent, @"expContent", flowId, @"flowId");
    
    [[TRNetWork sharedManager] requestURLPath:ST_API_uploadException httpMethod:TRRequestMethodPost parmas:sendDic completetion:^(id result, NSError *error) {
        TRBaseModel *model = [[TRBaseModel alloc] initWithDictionary:result];
        
        if (model.isStatusOK) {
//            TRLog(@"上传日志****");
        } else {
//            TRLog(@"上传日志xxxx");
        }
    }];
}

- (NSString *)appSEVER_IP_CORE_CN:(TransnEnvironment)environment
{
    if (environment == TransnEnvironmentProduct) {
        return SEVER_IP_Core_Product;
    } else if (environment == TransnEnvironmentDevelopment) {
        return SEVER_IP_Core_Development;
    } else if (environment == TransnEnvironmentTest) {
        return SEVER_IP_Core_Test;
    } else {
        return SEVER_IP_Core_Test;
    }
}



- (void)getMyIPCountry
{
    NSString *url = [NSString stringWithFormat:@"http://ip.taobao.com/service/getIpInfo.php?ip=myip"];
    
    [[TRNetWork sharedManager] requestURLPath:url httpMethod:TRRequestMethodPost parmas:nil completetion:^(id responseObject, NSError *error) {
        if (responseObject && [responseObject isKindOfClass:[NSDictionary class]]) {
            NSDictionary *dataDic = [responseObject objectForKey:@"data"];
            
            if (dataDic && [dataDic isKindOfClass:[NSDictionary class]]) {
                NSString *country_id = [dataDic objectForKey:@"country_id"];
                
                TRLog(@"country_id: %@", country_id);
                
                self.countryId = country_id;
                self.userIP = [dataDic objectForKey:@"ip"];
            }
        }
    }];
}

#pragma mark - Token获取和更新

- (void)getTwilioToken:(void (^)(NSError *error))completion
{
    if ([self.clientID length] == 0) {
        return;
    }
    
    __weak __typeof(self) weakSelf = self;
    
    //    http://103.244.232.18:8380/CORE_SERVER/ coreHost = @"103.244.232.18:8380/CORE_SERVER"
    
    NSString *coreHost = [self.coreServerIp stringByReplacingOccurrencesOfString:@"https://" withString:@""];
    coreHost = [coreHost stringByReplacingOccurrencesOfString:@"http://" withString:@""];
    
    if ([coreHost hasSuffix:@"/"]) {
        coreHost = [coreHost substringToIndex:coreHost.length - 1];
    }
    
    NSDictionary *dic = TRDicWithOAndK(@"1", @"isInit", self.clientID, @"clientId", coreHost, @"coreHost");
    [[TRNetWork sharedManager] requestURLPath:ST_API_twilio_getTwilioToken httpMethod:TRRequestMethodPost parmas:dic completetion:^(id responseObject, NSError *error) {
        TRBaseModel *model = [[TRBaseModel alloc] initWithDictionary:responseObject];
        
        if (model.isStatusOK) {
//            NSLog(@"%@",responseObject);
            self.twiiloToken = [model.data objectForKey:@"token"];
            
            if ([self.userIP length] == 0) {
                self.userIP = [model.data objectForKey:@"ip"];
            }
       
            NSString *userID = [model.data objectForKey:@"userId"];
            long long utcTimestamp = [[model.data objectForKey:@"utcTimestamp"] longLongValue];
            NSDate *datenow = [NSDate date];
            self.serverUtcTimestampDvalue = @(utcTimestamp - [datenow timeIntervalSince1970] * 1000);
            //            TRLog(@"newUserId: %@", userID);
            self.qiNiuUploadImageUrl = [model.data objectForKey:@"qiNiuUploadImageUrl"];
            self.qiNiuToken = [model.data objectForKey:@"qiNiuToken"];
            self.qiNiuBaseUrl = [model.data objectForKey:@"qiNiuBaseUrl"];
            self.timeToGetQiNiuToken = [NSDate date];
        
            NSString *xmppPort = [NSString stringWithFormat:@"%@", [model.data objectForKey:@"openfirePort"]];
            [XMPPManager sharedInstance].XMPP_DOMAIN = [NSString stringWithFormat:@"%@", [model.data objectForKey:@"xmppDomain"]];
            [XMPPManager sharedInstance].XMPP_HOST = [NSString stringWithFormat:@"%@", [model.data objectForKey:@"openfireHost"]];
            [XMPPManager sharedInstance].XMPP_PORT = [xmppPort intValue];
            [[XMPPManager sharedInstance] loginWithName:userID andPassword:userID];
            [TRNetWork sharedManager].userId = self.myUserID;
            if (completion) {
                completion(nil);
            }
            
            // 获取自己ip然后查询是哪个国家
            [weakSelf getMyIPCountry];
        } else {
            NSString *log = [NSString stringWithFormat:@"%@", [error description] == nil ? responseObject[@"msg"] :[error description]];
            [weakSelf printLog:log];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self getTwilioToken:completion];
            });
        }
    }];
}

- (void)updataQiuniuToken:(void (^)(NSError *error))completion
{
    BOOL isNeedRefresh = YES;
    
    if (self.qiNiuUploadImageUrl && self.qiNiuToken && self.qiNiuBaseUrl && self.timeToGetQiNiuToken) {
        NSDate  *nowDate = [NSDate date];
        int     tick = [nowDate timeIntervalSinceDate:self.timeToGetQiNiuToken];
        
        if (tick > 60 * 20) {
            // 20分钟刷新一次
        } else {
            isNeedRefresh = NO;
        }
    }
    
    if (isNeedRefresh||!completion) {
        NSDictionary *dic = TRDicWithOAndK(self.clientID, @"clientId");
        [[TRNetWork sharedManager] requestURLPath:ST_API_twilio_getTwilioToken httpMethod:TRRequestMethodPost parmas:dic completetion:^(id responseObject, NSError *error) {
            TRBaseModel *model = [[TRBaseModel alloc] initWithDictionary:responseObject];
            
            if (model.isStatusOK) {
                self.qiNiuUploadImageUrl = [model.data objectForKey:@"qiNiuUploadImageUrl"];
                self.qiNiuToken = [model.data objectForKey:@"qiNiuToken"];
                self.qiNiuBaseUrl = [model.data objectForKey:@"qiNiuBaseUrl"];
                self.timeToGetQiNiuToken = [NSDate date];
                [self printLog:@"更新七牛Token成功"];
                
                if (completion) {
                    completion(nil);
                }
            } else {
                //不管成功失败，都返回成功
                if (completion) {
                    completion(nil);
                }
            }
        }];
    } else {
        if (completion) {
            completion(nil);
        }
    }
}

- (void)uploadData:(NSData *)data fileName:(NSString *)fileName withExtention:(NSString *)ext completionHandler:(void (^)(NSString *fileUrl, NSError *error))completionHandler{
    [self updataQiuniuToken:^(NSError *error) {
        if (error) {
            completionHandler(@"", error);
        } else {
            NSMutableDictionary *mDic = [[NSMutableDictionary alloc] init];
            [mDic setValue:self.qiNiuToken forKey:@"token"];
            NSString *keyName = fileName;
            if (keyName) {
                
            }else{
                    NSString *dateStr =   [NSDate currentDate:@"YYYYMMddHHmmssSSS"];
                    keyName = [NSString stringWithFormat:@"%@_%@.%@", [TransnSDK shareManger].myUserID,dateStr, ext];
            }
            [mDic setValue:keyName forKey:@"key"];
//            [mDic setValue:@"image.png" forKey:@"file"];
//            NSLog(@"url:%@,key:%@,mdic:%@",self.qiNiuUploadImageUrl,keyName,mDic);
            [[TRNetWork sharedManager] postFile:data url:self.qiNiuUploadImageUrl name:@"file" fileName:keyName params:mDic extention:ext completionHandler:^(NSDictionary *returnDic, NSError *error) {
                NSString *fileName = [returnDic objectForKey:@"key"];
                
                if (error || ([fileName length] == 0)) {
                    //刷新token
                    [self updataQiuniuToken:nil];
                    completionHandler(@"", error);
                } else {
                    NSString *imageUrl = [NSString stringWithFormat:@"%@%@", self.qiNiuBaseUrl, fileName];
                    completionHandler(imageUrl, error);
                }
            }];
      
        }
    }];
}
- (NSString *)getBuildVersion{
    return @"2.0.1";
}
@end
