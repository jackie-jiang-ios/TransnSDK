//
//  TRFileDownLoad.m
//  TransnSDK
//
//  Created by 姜政 on 2017/11/24.
//  Copyright © 2017年 Transn. All rights reserved.
//

#import "TRFileDownLoad.h"
typedef void (^ DownLoadBlock)(NSString *fliePath, NSError *error);
@interface TRFileDownLoad () <NSURLSessionDownloadDelegate>{}
@property(nonatomic, copy) DownLoadBlock loadFinishBlock;
@end

@implementation TRFileDownLoad
- (instancetype)initWithDownLoadFile:(NSString *)fileUrlPath queue:(NSOperationQueue *)downLoadQueue completetion:(DownLoadBlock)completion
{
    if (self = [super init]) {
        if (completion) {
            _loadFinishBlock = [completion copy];
        }
        
        // 创建会话
        NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration
                                                                        defaultSessionConfiguration] delegate:self delegateQueue:downLoadQueue];
        // 确定URL
        NSURL *url = [NSURL URLWithString:fileUrlPath];
        // 通过会话在确定的URL上创建下载任务
        NSURLSessionDownloadTask *downloadTask = [session downloadTaskWithURL:url];
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        NSString *homePath = [paths objectAtIndex:0];
        NSString *directorPath = [homePath stringByAppendingPathComponent:@"TransnSDK"];

        NSString *fullPath =
        [directorPath
         stringByAppendingPathComponent:downloadTask.response.suggestedFilename];
        NSFileManager   *fm = [NSFileManager defaultManager];
        BOOL            isDir = NO;
        
        if ([fm fileExistsAtPath:fullPath isDirectory:&isDir] && downloadTask.response.suggestedFilename) {
            if (completion) {
//                NSLog(@"已经存在:%@", fullPath);
                completion(fullPath, nil);
            }
            
            // 就不用下载了
            return self;
        }
        
        // 启动任务
        [downloadTask resume];
    }
    
    return self;
}

// 下载了数据的过程中会调用的代理方法
- (void)URLSession          :(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten
        totalBytesWritten   :(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    //    NSLog(@"%lf",1.0 * totalBytesWritten / totalBytesExpectedToWrite);
}

// 重新恢复下载的代理方法
- (void)URLSession          :(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
        didResumeAtOffset   :(int64_t)fileOffset expectedTotalBytes:(int64_t)expectedTotalBytes {}

// 写入数据到本地的时候会调用的方法
- (void)URLSession                  :(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
        didFinishDownloadingToURL   :(NSURL *)location
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *homePath = [paths objectAtIndex:0];
    NSString *directorPath = [homePath stringByAppendingPathComponent:@"TransnSDK"];
    
    NSString *fullPath =
    [directorPath
     stringByAppendingPathComponent:downloadTask.response.suggestedFilename];
    
    [[NSFileManager defaultManager] moveItemAtURL:location
                                         toURL   :[NSURL fileURLWithPath:fullPath]
                                         error   :nil];
    
    if (_loadFinishBlock) {
        _loadFinishBlock(fullPath, nil);
    }
}

// 请求完成，错误调用的代理方法
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    if (self.loadFinishBlock) {
        _loadFinishBlock(nil, error);
    }
}

+ (instancetype)downLoadFile:(NSString *)fileUrlPath queue:(NSOperationQueue *)downLoadQueue completetion:(void (^) (NSString *filePath, NSError *error))completion
{
    TRFileDownLoad *fileDownLoad = [[TRFileDownLoad alloc] initWithDownLoadFile:fileUrlPath queue:downLoadQueue completetion:completion];
    
    return fileDownLoad;
}

@end
