//
//  NSObject+TRKeyValue.h
//  TransnSDK
//
//  Created by 姜政 on 2018/4/17.
//  Copyright © 2018年 Transn. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (TRKeyValue)
#pragma mark - 转换为JSON
/**
 *  转换为JSON Data
 */
- (NSData *)tr_JSONData;
/**
 *  转换为字典或者数组
 */
- (id)tr_JSONObject;
/**
 *  转换为JSON 字符串
 */
- (NSString *)tr_JSONString;
@end
