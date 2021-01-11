//
//  TRFileLog.h
//  TransnSDK
//
//  Created by 姜政 on 2017/8/17.
//  Copyright © 2017年 Transn. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TRFileLog : NSObject {
    dispatch_queue_t _writeDataQueue;
}
@property (nonatomic) BOOL logEnabled;

@property (nonatomic) BOOL logAllEnabled;
+ (instancetype)sharedManager;

- (void)log:(NSString *)format, ...;
- (void)writeToast:(NSString *)message;
- (void)writeErrorLog:(NSString *)expTitle expMsg:(NSString *)expContent flowId:(NSString *)flowId;
- (void)writeContent:(NSString *)string toFile:(NSString *)fileName;

- (void)writeContent:(NSString *)string toFilePath:(NSString *)filePath success:(void (^)(BOOL success,NSString *fliePath))successBlock;
@end
