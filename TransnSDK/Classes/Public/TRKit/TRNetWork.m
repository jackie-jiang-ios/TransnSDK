//
//  TRNetWork.m
//  TransnSDK
//
//  Created by 姜政 on 2017/8/17.
//  Copyright © 2017年 Transn. All rights reserved.
//

#import "TRNetWork.h"
#import "TROpenUDID.h"
#import <AdSupport/ASIdentifierManager.h>
#import <sys/utsname.h>                 // import it in your header or implementation file.
#import <CommonCrypto/CommonDigest.h>   // MD5
#import "TRPrivateConstants.h"
#import "TRFileDownLoad.h"
#import "TRSafeJSON.h"

/**
 Returns a percent-escaped string following RFC 3986 for a query string key or value.
 RFC 3986 states that the following characters are "reserved" characters.
    - General Delimiters: ":", "#", "[", "]", "@", "?", "/"
    - Sub-Delimiters: "!", "$", "&", "'", "(", ")", "*", "+", ",", ";", "="

 In RFC 3986 - Section 3.4, it states that the "?" and "/" characters should not be escaped to allow
 query strings to include a URL. Therefore, all "reserved" characters with the exception of "?" and "/"
 should be percent-escaped in the query string.
    - parameter string: The string to be percent-escaped.
    - returns: The percent-escaped string.
 */
NSString * TRPercentEscapedStringFromString(NSString *string) {
    static NSString * const kAFCharactersGeneralDelimitersToEncode = @":#[]@"; // does not include "?" or "/" due to RFC 3986 - Section 3.4
    static NSString * const kAFCharactersSubDelimitersToEncode = @"!$&'()*+,;=";

    NSMutableCharacterSet * allowedCharacterSet = [[NSCharacterSet URLQueryAllowedCharacterSet] mutableCopy];
    [allowedCharacterSet removeCharactersInString:[kAFCharactersGeneralDelimitersToEncode stringByAppendingString:kAFCharactersSubDelimitersToEncode]];

    // FIXME: https://github.com/AFNetworking/AFNetworking/pull/3028
    // return [string stringByAddingPercentEncodingWithAllowedCharacters:allowedCharacterSet];

    static NSUInteger const batchSize = 50;

    NSUInteger index = 0;
    NSMutableString *escaped = @"".mutableCopy;

    while (index < string.length) {
        NSUInteger length = MIN(string.length - index, batchSize);
        NSRange range = NSMakeRange(index, length);

        // To avoid breaking up character sequences such as 👴🏻👮🏽
        range = [string rangeOfComposedCharacterSequencesForRange:range];

        NSString *substring = [string substringWithRange:range];
        NSString *encoded = [substring stringByAddingPercentEncodingWithAllowedCharacters:allowedCharacterSet];
        [escaped appendString:encoded];

        index += range.length;
    }

    return escaped;
}

@interface TRQueryStringPair : NSObject
@property (readwrite, nonatomic, strong) id field;
@property (readwrite, nonatomic, strong) id value;

- (instancetype)initWithField:(id)field value:(id)value;

- (NSString *)URLEncodedStringValue;
@end

@implementation TRQueryStringPair

- (instancetype)initWithField:(id)field value:(id)value {
    self = [super init];
    if (!self) {
        return nil;
    }

    self.field = field;
    self.value = value;

    return self;
}

- (NSString *)URLEncodedStringValue {
    if (!self.value || [self.value isEqual:[NSNull null]]) {
        return TRPercentEscapedStringFromString([self.field description]);
    } else {
        return [NSString stringWithFormat:@"%@=%@", TRPercentEscapedStringFromString([self.field description]), TRPercentEscapedStringFromString([self.value description])];
    }
}

@end

#pragma mark -




NSArray * TRQueryStringPairsFromKeyAndValue(NSString *key, id value) {
    NSMutableArray *mutableQueryStringComponents = [NSMutableArray array];

    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"description" ascending:YES selector:@selector(compare:)];

    if ([value isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dictionary = value;
        // Sort dictionary keys to ensure consistent ordering in query string, which is important when deserializing potentially ambiguous sequences, such as an array of dictionaries
        for (id nestedKey in [dictionary.allKeys sortedArrayUsingDescriptors:@[ sortDescriptor ]]) {
            id nestedValue = dictionary[nestedKey];
            if (nestedValue) {
                [mutableQueryStringComponents addObjectsFromArray:TRQueryStringPairsFromKeyAndValue((key ? [NSString stringWithFormat:@"%@[%@]", key, nestedKey] : nestedKey), nestedValue)];
            }
        }
    } else if ([value isKindOfClass:[NSArray class]]) {
        NSArray *array = value;
        for (id nestedValue in array) {
            [mutableQueryStringComponents addObjectsFromArray:TRQueryStringPairsFromKeyAndValue([NSString stringWithFormat:@"%@[]", key], nestedValue)];
        }
    } else if ([value isKindOfClass:[NSSet class]]) {
        NSSet *set = value;
        for (id obj in [set sortedArrayUsingDescriptors:@[ sortDescriptor ]]) {
            [mutableQueryStringComponents addObjectsFromArray:TRQueryStringPairsFromKeyAndValue(key, obj)];
        }
    } else {
        [mutableQueryStringComponents addObject:[[TRQueryStringPair alloc] initWithField:key value:value]];
    }

    return mutableQueryStringComponents;
}
NSArray * TRQueryStringPairsFromDictionary(NSDictionary *dictionary) {
    return TRQueryStringPairsFromKeyAndValue(nil, dictionary);
}

#pragma mark -
NSString * TRQueryStringFromParameters(NSDictionary *parameters) {
    NSMutableArray *mutablePairs = [NSMutableArray array];
    for (TRQueryStringPair *pair in TRQueryStringPairsFromDictionary(parameters)) {
        [mutablePairs addObject:[pair URLEncodedStringValue]];
    }

    return [mutablePairs componentsJoinedByString:@"&"];
}

@interface TRNetWork () {
    NSOperationQueue *downLoadQueue;
    dispatch_queue_t _postDataQueue;
}
@property(nonatomic,copy)NSString *authorization;

#pragma mark private
/**
 *   获取Core server ID
 *
 *   @param defaultMode 调试模式
 *   @return 字符串
 */
//- (NSString *)appSEVER_IP_CORE_CN:(TransnEnvironment)defaultMode;

/**
 *   组合需要传的公共参数
 *
 *   @param params 非公共参数
 *   @return 所有参数
 */
- (NSDictionary *)sendParams:(NSDictionary *)params;

/**
 *   当前机器的语音
 *
 *   @return 字符串
 */
- (NSString *)Language;
@end

@implementation TRNetWork
+ (instancetype)sharedManager{
    static id _instace = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instace = [[self alloc] init];
    });
    return _instace;
}
#pragma mark Public

- (void)setAuthorizationHeaderFieldWithUsername:(NSString *)username
                                       password:(NSString *)password
{
    NSData *basicAuthCredentials = [[NSString stringWithFormat:@"%@:%@", username, password] dataUsingEncoding:NSUTF8StringEncoding];
    NSString *base64AuthCredentials = [basicAuthCredentials base64EncodedStringWithOptions:(NSDataBase64EncodingOptions)0];
    self.authorization = [NSString stringWithFormat:@"Basic %@", base64AuthCredentials];
}
#pragma mark private

- (NSString *)Language
{
    NSString *currentLanguage = [[NSLocale preferredLanguages] objectAtIndex:0];
    
    return currentLanguage;
}

- (NSDictionary *)sendParams:(NSDictionary *)params
{
    NSMutableDictionary *sendDic = [params mutableCopy];
    
    if (sendDic == nil) {
        sendDic = [[NSMutableDictionary alloc] init];
    }
    
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString    *deviceString = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    NSString    *appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSString    *bundleID = [[NSBundle mainBundle] bundleIdentifier];
    NSString    *idfa = [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
    NSString    *appName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"];
    NSString    *language = [self Language];
    NSDate      *datenow = [NSDate date];
    
    NSString    *appKey = self.appKey;
    NSString    *time = [NSString stringWithFormat:@"%lld", (long long)([datenow timeIntervalSince1970] * 1000)];
    [sendDic setObject:[TransnSDK getVersion] forKey:@"SDKVersion"];// SDK 版本号，int型
    [sendDic setObject:appVersion forKey:@"appVersion"];
    [sendDic setObject:[TROpenUDID  value] forKey:@"udid"];
    [sendDic setObject:deviceString forKey:@"deviceModel"]; //
    [sendDic setObject:[[UIDevice currentDevice] systemVersion] forKey:@"sysVersion"];
    [sendDic setObject:@"1" forKey:@"system"];
    if (idfa) {
       [sendDic setObject:idfa forKey:@"idfa"];// 广告标示
    }
    [sendDic setObject:bundleID forKey:@"bundleID"];                                // App 标识：com.transn.mobile.lxzry
    [sendDic setObject:appName forKey:@"appName"];                                  // App 名称如：小尾巴翻译
    [sendDic setObject:[NSString stringWithFormat:@"%@", appKey] forKey:@"appKey"]; // AppID 服务器提供的
    [sendDic setValue:language forKey:@"language"];                                 // 系统语言 如 zh-Hans（跟TE公共参数的local有区别）
    [sendDic setValue:time forKey:@"timeStamp"];
    if ([sendDic objectForKey:@"userId"]) {
        ///外部的userID
    }else{
        if ([self.userId length] > 0) {
            [sendDic setObject:self.userId forKey:@"userId"];
        }
    }
    if (self.addCommonDataBlock) {
          TRCommonDataBlock commonDataBlock = ^(NSDictionary *params) {
              NSArray *allKeys = params.allKeys;
              for (int i= 0; i<allKeys.count; i++) {
                  if (!sendDic[allKeys[i]]) {
                      sendDic[allKeys[i]] = params[allKeys[i]];
                  }
              }
          };
          self.addCommonDataBlock(commonDataBlock);
      }
    
    sendDic = [self addEncryptSignToDic:sendDic];
    return sendDic;
}

- (NSMutableDictionary *)addEncryptSignToDic:(NSDictionary *)dic
{
    NSString *appSecret = self.appSecret;

    NSMutableDictionary *sendDic = [dic mutableCopy];
    NSMutableDictionary *tmpDic = [[NSMutableDictionary alloc] initWithDictionary:sendDic];
    
    [tmpDic setValue:appSecret forKey:@"appSecret"];
    NSArray *keysArray = [tmpDic allKeys];
    
    NSSortDescriptor    *descriptor = [NSSortDescriptor sortDescriptorWithKey:nil ascending:YES];
    NSArray             *descriptors = [NSArray arrayWithObject:descriptor];
    NSArray             *sortArray = [keysArray sortedArrayUsingDescriptors:descriptors];
    
    NSString *postBodyStr = @"";
    
    for (NSString *key in sortArray) {
        if ([[NSString stringWithFormat:@"%@", [tmpDic valueForKey:key]] length] > 0) {
            postBodyStr = [NSString stringWithFormat:@"%@%@=%@&", postBodyStr, key, [tmpDic valueForKey:key]];
        }
    }
    
    postBodyStr = [postBodyStr substringToIndex:postBodyStr.length - (postBodyStr.length > 0)];
    //    TRLog(@"%@",postBodyStr);
    NSString *md5Str = [self encrypt32MD5:postBodyStr];
    [sendDic setValue:md5Str forKey:@"sign"];// 所有post的Key排序以后使用&评测字符串（如上），然后进行MD5加密
    
    return sendDic;
}

// - (NSString *)URLEncodedString:(NSString *)string
// {
//    NSString *encodedString = (NSString *)
//    CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
//                                                              (CFStringRef)string,
//                                                              NULL,
//                                                              (CFStringRef)@"!$&'()*+,-./:;=?@_~%#[]",
//                                                              kCFStringEncodingUTF8));
//    return encodedString;
// }

- (NSString *)encrypt32MD5:(NSString *)encryptStr
{
    const char      *cStr = [encryptStr UTF8String];
    unsigned char   result[32];
    
    CC_MD5(cStr, (CC_LONG)strlen(cStr), result);
    return [[NSString stringWithFormat:
             @"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
             result[0], result[1], result[2], result[3],
             result[4], result[5], result[6], result[7],
             result[8], result[9], result[10], result[11],
             result[12], result[13], result[14], result[15]
             ] lowercaseString];
}

- (NSString *)addCommonData:(NSDictionary *)dataBody ToUrl:(NSString *)url
{
    NSString    *strUrl = [url copy];
    NSString    *postBodyStr = @"";
    NSRange     isRange = [strUrl rangeOfString:@"?" options:NSCaseInsensitiveSearch];
    
    for (NSString *key in [dataBody keyEnumerator]) {
        NSString    *appendStr = [NSString stringWithFormat:@"%@=%@&", key, [dataBody valueForKey:key]];
        NSRange     isRangeTmep = [url rangeOfString:appendStr options:NSCaseInsensitiveSearch];
        
        if (isRangeTmep.location == NSNotFound) {
            postBodyStr = [NSString stringWithFormat:@"%@%@", postBodyStr, appendStr];
        }
    }
    
    postBodyStr = [postBodyStr substringToIndex:postBodyStr.length - (postBodyStr.length > 0)];
    
    if (isRange.location == NSNotFound) {
        strUrl = [NSString stringWithFormat:@"%@?%@", url, postBodyStr];
    } else {
        strUrl = [NSString stringWithFormat:@"%@&%@", url, postBodyStr];
    }
    
    return strUrl;
}


#pragma mark -

- (NSURLSessionDataTask *)requestURLPath:(NSString *)urlPath httpMethod:(TRRequestMethod)httpMethod parmas:(NSDictionary *)parmas completetion:(void (^) (id responseObject, NSError *error))completion
{
    NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorBadURL userInfo:nil];
    
    if (([urlPath length] == 0) && completion) {
        completion(nil, error);
    }
    
    NSURL               *url = [NSURL URLWithString:urlPath];
    NSMutableURLRequest *request;
    
    if (httpMethod == TRRequestMethodPost) {
        request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:30];
        NSDictionary *sendParams = [self sendParams:parmas];
        TRLog(@"url:%@ \n sendParams:%@",urlPath,sendParams);
        NSString *query = nil;
        if (sendParams) {
            ///需要在参数组成前把特殊字符处理掉
            query = TRQueryStringFromParameters(sendParams);
        }
        if (query && query.length > 0) {
            NSData *data  =[query dataUsingEncoding:NSUTF8StringEncoding];
            [request setHTTPBody:data];
        }
        [request setHTTPMethod:@"POST"];  // 设置请求方式为POST，默认为GET

    }else if (httpMethod == TRRequestMethodJsonPost){
        request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:30];
        NSDictionary *sendParams = [self sendParams:parmas];
        TRLog(@"url:%@ \n sendParams:%@",urlPath,sendParams);
        NSError*err = nil;
        NSData *data =  [NSJSONSerialization dataWithJSONObject:sendParams options:NSJSONWritingPrettyPrinted error:&err];
        [request setHTTPBody:data];
        [request setHTTPMethod:@"POST"];  // 设置请求方式为POST，默认为GET
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    } else {
        NSDictionary    *sendParams = [self sendParams:parmas];
        NSString        *urlWithGetParm = [self addCommonData:sendParams ToUrl:urlPath];
        // 第一步，创建URL
        NSURL *tmpUrl = [NSURL URLWithString:urlWithGetParm];
        // 第二步，通过URL创建网络请求
        // NSURLRequest初始化方法第一个参数：请求访问路径，第二个参数：缓存协议，第三个参数：网络请求超时时间（秒）
        request = [[NSMutableURLRequest alloc]initWithURL:tmpUrl cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10];
    }
    if (self.authorization) {
        [request setValue:self.authorization forHTTPHeaderField:@"Authorization"];
        
    }

    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request
                                                                 completionHandler:^(NSData *_Nullable data, NSURLResponse *_Nullable response, NSError *_Nullable error) {
                                                                     NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                                                                     
                                                                    TRLog(@"response status code: %ld", (long)[httpResponse statusCode]);
                                                                     if ([httpResponse statusCode] == 200) {
                                                                         NSError *error1;
                                                                         id returnValue = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error1];
                                                                         TRSafeJSON *safeJson = [[TRSafeJSON alloc] init];
                                                                         id safeValue = [safeJson cleanUpJson:returnValue];
                                                                         TRLog(@"%@",safeValue);
                                                                         dispatch_async(dispatch_get_main_queue(), ^{
                                                                             if (completion) {
                                                                                 completion(safeValue, error1);
                                                                             }
                                                                         });
                                                                     } else {
                                                                         dispatch_async(dispatch_get_main_queue(), ^{
                                                                             if (!completion)return ;
                                                                             if (!error) {
                                                                                 completion(nil, [TRError errorWithDomain:nil code:70000 description:[NSString stringWithFormat:@"请求错误，statusCode:%@",@(httpResponse.statusCode)]]);
                                                                             }else{
                                                                                 completion(nil, error);
                                                                             }
                                                                           
                                                                         });
                                                                     }
                                                                 }];
    [task resume];
    return task;
}

- (void)postFile:(NSData *)fileData url:(NSString *)url name:(NSString *)name fileName:(NSString *)fileName params:(NSDictionary *)params extention:(NSString *)ext completionHandler:(void (^)(NSDictionary *returnDic, NSError *error))completionHandler{
    
    if (!_postDataQueue) {
        const char *queueName = "com.transn.postDataQueue";
        _postDataQueue = dispatch_queue_create(queueName, DISPATCH_QUEUE_SERIAL);
    }
    dispatch_async(_postDataQueue, ^{
        NSURL *URL = [[NSURL alloc] initWithString:url];
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:URL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30];
        request.HTTPMethod = @"POST";
        NSString *boundary = @"werghnvt54wef654rjuhgb56trtg34tweuyrgf";
        request.allHTTPHeaderFields = @{
                                        @"Content-Type" : [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary]
                                        };
        NSMutableData *postData = [[NSMutableData alloc] init];
        for (NSString *paramsKey in params) {
            NSString *pair = [NSString stringWithFormat:@"--%@\r\nContent-Disposition: form-data; name=\"%@\"\r\n\r\n", boundary, paramsKey];
            [postData appendData:[pair dataUsingEncoding:NSUTF8StringEncoding]];
            
            id value = [params objectForKey:paramsKey];
            if ([value isKindOfClass:[NSString class]]) {
                [postData appendData:[value dataUsingEncoding:NSUTF8StringEncoding]];
            } else if ([value isKindOfClass:[NSData class]]) {
                [postData appendData:value];
            }
            [postData appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        }
        NSString *filePair = [NSString stringWithFormat:@"--%@\r\nContent-Disposition: form-data; name=\"%@\"; filename=\"%@\"\nContent-Type:%@\r\n\r\n", boundary, name, fileName, @"application/octet-stream"];
        [postData appendData:[filePair dataUsingEncoding:NSUTF8StringEncoding]];
        [postData appendData:fileData];
        [postData appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        request.HTTPBody = postData;
        [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)postData.length] forHTTPHeaderField:@"Content-Length"];
        NSURLSession            *session = [NSURLSession sharedSession];
        NSURLSessionDataTask    *dataTask = [session uploadTaskWithRequest:request fromData:nil completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (data) {
                    id returnValue = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                    TRSafeJSON *safeJson = [[TRSafeJSON alloc] init];
                    id safeValue = [safeJson cleanUpJson:returnValue];
                    if (completionHandler) {
                        completionHandler(safeValue, error);
                    }
                } else {
                    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"fail" forKey:NSLocalizedDescriptionKey];
                    NSError *aError = [NSError errorWithDomain:@"" code:10001 userInfo:userInfo];
                    completionHandler(nil, aError);
                }
            });
         
        }];
        [dataTask resume];
    });
   
}
- (void)appendUTF8Body:(NSMutableData *)body dataString:(NSString *)dataString {
    [body appendData:[dataString dataUsingEncoding:NSUTF8StringEncoding]];
}
- (void)downLoadFile:(NSString *)fileUrlPath completetion:(void (^) (NSString *filePath, NSError *error))completion
{
    if (!downLoadQueue) {
        downLoadQueue = [[NSOperationQueue alloc] init];
    }
    
    [TRFileDownLoad downLoadFile:fileUrlPath queue:downLoadQueue completetion:completion];
}

- (void)dealloc
{

    if (downLoadQueue) {
        downLoadQueue = nil;
    }
    if (_postDataQueue) {
        _postDataQueue = nil;
    }
}

@end
