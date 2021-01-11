//
//  TRFileLog.m
//  TransnSDK
//
//  Created by 姜政 on 2017/8/17.
//  Copyright © 2017年 Transn. All rights reserved.
//

#import "TRFileLog.h"
#import "TransnSDK.h"
#import "NSDate+TRExtension.h"
#import "TransnSDK+Private.h"
dispatch_queue_t myQueue;
@implementation TRFileLog

+ (instancetype)sharedManager{
    static id _instace = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instace = [[self alloc] init];
    });
    return _instace; 
}

- (void)log:(NSString *)format, ...{
    if (self.logEnabled) {
        va_list args;
        va_start(args, format);
        NSString *str = [[NSString alloc] initWithFormat:format arguments:args];
        NSLog(@"%@", str);
        va_end(args);
    }
}

- (void)writeToast:(NSString *)message
{
    if (self.logEnabled) {
        if ([TransnSDK shareManger].clientID) {
            NSString *fileName = [NSString stringWithFormat:@"%@_totst_%@.log", [TransnSDK shareManger].clientID, [NSDate currentDate:@"YYYYMMdd"]];
            
            [self writeContent:message toFile:fileName];
        } else {
            // 未登录就不要存了，没啥用
        }
    }
}

- (void)writeErrorLog:(NSString *)expTitle expMsg:(NSString *)expContent flowId:(NSString *)flowId
{
    if (self.logEnabled) {
        NSString    *fileName = [NSString stringWithFormat:@"%@_exception_%@.txt", [TransnSDK shareManger].myUserID, [NSDate currentDate:@"YYYYMMdd"]];
        NSString    *fileContent = [NSString stringWithFormat:@"ip : %@, expTitle : %@, expContent : %@,flowId: %@", [TransnSDK shareManger].userIP, expTitle, expContent, flowId];
        
        [self writeContent:fileContent toFile:fileName];
    }
}

- (void)writeContent:(NSString *)string toFile:(NSString *)fileName
{
    // Cache目录  location of discardable cache files (Library/Caches)
    if (!_writeDataQueue) {
        const char *queueName = "com.transn.writeDataQueue";
        // DISPATCH_QUEUE_SERIAL 串行队列
        _writeDataQueue = dispatch_queue_create(queueName, DISPATCH_QUEUE_SERIAL);
    }
    
    dispatch_async(_writeDataQueue, ^{
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        NSString *homePath = [paths objectAtIndex:0];
        NSString *directorPath = [homePath stringByAppendingPathComponent:@"TransnSDK"];
        NSString *filePath = [directorPath stringByAppendingPathComponent:[NSString stringWithFormat:@"/%@", fileName]];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        BOOL isDir = NO;
        BOOL existed = [fileManager fileExistsAtPath:directorPath isDirectory:&isDir];
        
        if (!((isDir == YES) && (existed == YES))) {
            [fileManager createDirectoryAtPath:directorPath withIntermediateDirectories:YES attributes:nil error:nil];
        }
        
        if (![fileManager fileExistsAtPath:filePath]) { // 如果不存在
            NSString *str = fileName;
            [str writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
        }
        
        NSFileHandle *fileHandle = [NSFileHandle fileHandleForUpdatingAtPath:filePath];
        
        [fileHandle seekToEndOfFile];  // 将节点跳到文件的末尾
        
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        NSString *datestr = [dateFormatter stringFromDate:[NSDate date]];
        
        NSString *str = [NSString stringWithFormat:@"\n%@ : %@", datestr, string];
        
        NSData *stringData = [str dataUsingEncoding:NSUTF8StringEncoding];
        
        [fileHandle writeData:stringData]; // 追加写入数据
        
        [fileHandle closeFile];
    });
}
- (void)writeContent:(NSString *)string toFilePath:(NSString *)filePath success:(void (^)(BOOL success,NSString *fliePath))successBlock{
    // Cache目录  location of discardable cache files (Library/Caches)
    if (!_writeDataQueue) {
        const char *queueName = "com.transn.writeDataQueue";
        // DISPATCH_QUEUE_SERIAL 串行队列
        _writeDataQueue = dispatch_queue_create(queueName, DISPATCH_QUEUE_SERIAL);
    }
    NSString *fileToPath = filePath;
    if (fileToPath) {
        
    }else{
        NSString *dateStr =   [NSDate currentDate:@"YYYYMMddHHmmssSSS"];
        NSString* fileName = [NSString stringWithFormat:@"/%@_srcText_%@.txt", [TransnSDK shareManger].myUserID, dateStr];
        NSString * tmpDir = NSTemporaryDirectory();
        fileToPath = [tmpDir stringByAppendingPathComponent:fileName];
    }
 
 
    dispatch_async(_writeDataQueue, ^{
//        NSFileManager *fileManager = [NSFileManager defaultManager];
//        BOOL isDir = NO;
//        BOOL existed = [fileManager fileExistsAtPath:fileToPath isDirectory:&isDir];
        BOOL success = NO;
       
        success = [string writeToFile:fileToPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
        if (successBlock) {
            successBlock(success,fileToPath);
        }
    });
}
- (void)dealloc
{
    _writeDataQueue = NULL;
}

@end
