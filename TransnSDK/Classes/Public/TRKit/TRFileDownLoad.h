//
//  TRFileDownLoad.h
//  TransnSDK
//
//  Created by 姜政 on 2017/11/24.
//  Copyright © 2017年 Transn. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TRFileDownLoad : NSObject

+ (instancetype)downLoadFile:(NSString *)fileUrlPath queue:(NSOperationQueue *)downLoadQueue completetion:(void (^) (NSString *filePath, NSError *error))completion;

@end
