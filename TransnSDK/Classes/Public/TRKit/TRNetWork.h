//
//  TRNetWork.h
//  TransnSDK
//
//  Created by 姜政 on 2017/8/17.
//  Copyright © 2017年 Transn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TRConstants.h"
typedef NS_ENUM(NSInteger, TRRequestMethod)
{
 TRRequestMethodPost = 1,
 TRRequestMethodGet = 2,
 TRRequestMethodPut = 3,
 TRRequestMethodDelete = 4,
    ///加一个特殊的类型，表示跟普通的post方式不一样
 TRRequestMethodJsonPost = 5,
};
typedef void (^ TRCommonDataBlock) (NSDictionary *params);

@interface TRNetWork : NSObject
@property(nonatomic,copy)NSString *appKey;
@property(nonatomic,copy)NSString *appSecret;
@property(nonatomic,copy)NSString *userId;
@property (nonatomic, copy) void(^addCommonDataBlock)(TRCommonDataBlock commonDataBlock);


+ (instancetype)sharedManager;

- (NSURLSessionDataTask *)requestURLPath:(NSString *)urlPath httpMethod:(TRRequestMethod )httpMethod parmas:(NSDictionary *)parmas completetion:(void (^) (id responseObject, NSError *error))completion;

- (void)downLoadFile:(NSString *)fileUrlPath completetion:(void (^) (NSString *filePath, NSError *error))completion;

- (void)postFile:(NSData *)fileData url:(NSString *)url name:(NSString *)name fileName:(NSString *)fileName params:(NSDictionary *)params extention:(NSString *)ext completionHandler:(void (^)(NSDictionary *returnDic, NSError *error))completionHandler;

/**
 Sets the "Authorization" HTTP header set in request objects made by the HTTP client to a basic authentication value with Base64-encoded username and password. This overwrites any existing value for this header.

 @param username The HTTP basic auth username
 @param password The HTTP basic auth password
 */
- (void)setAuthorizationHeaderFieldWithUsername:(NSString *)username
                                       password:(NSString *)password;
@end
