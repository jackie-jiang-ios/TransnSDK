//
//  TRFileObject.h
//  TransnSDK
//
//  Created by 姜政 on 2018/4/20.
//  Copyright © 2018年 Transn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/*!
 *    预约单内容类型枚举
 */
typedef NS_ENUM (NSInteger, TRFileObjectType) {
    /*!翻译文本*/
    TRFileObjectTypeText = 0,
    /*!翻译图片*/
    TRFileObjectTypeImage = 1,
    //暂时没有语音消息
};


@interface TRFileObject : NSObject
#pragma mark 上传文件请求参数
/*!
 *    预约单内容类型
 */
@property(nonatomic,assign)TRFileObjectType type;
/*!
 *    非必填，文件名称，在获取文件ID之前都可以修改，如果要修改这个，就得重新再获取一次fileId,译员端不会显示文件名称
 */
@property(nonatomic,copy)NSString *fileName;
/*!
 *    预约单文本内容，文字和图片，只能有一个
 */
@property(nonatomic,copy)NSString *srcText;
/*!
 *    预约单图片内容，文字和图片，只能有一个,上传成功会把srcImage至为nil
 */
@property(nonatomic,strong)UIImage  *srcImage;
/*!
 *    原语种ID
 */
@property(nonatomic,copy)NSString *srcLanguageId;
/*!
 *    目标语种ID
 */
@property(nonatomic,copy)NSString *tarLanguageId;

/*!
 *    译员ID,普通预约和直接对某一个译员预约的时长计算方法不一样，这个字段是后来加的
 */
@property(nonatomic,copy)NSString *translatorId;

/*!
 *    扩展字段，暂无
 */
@property(nonatomic,strong)NSDictionary  *extraParams;

#pragma mark  上传文件返回参数
/*!
 *    请求FileId时，系统会去识别语种ID，但是以用户选择语种为准
 */
@property(nonatomic,copy)NSString *recognizerLangId;
/*!
 *    预约单图片内容，生成的链接,同一段文字或者图片，已经获取链接了，就不用再传文字或者图片对象了
 */
@property(nonatomic,copy)NSString *fileUrl;

/*!
 *    翻译文件唯一标识
 */
@property(nonatomic,copy)NSString *fileId;

/*!
 *   重要->是否可以统计 1：可以统计  0：无法统计，无法统计就不能下单了
 */
@property(nonatomic,assign)BOOL isStat;
/*!
 *    总字数
 */
@property(nonatomic,copy)NSString *count;

@end
