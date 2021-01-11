/*!
 *   TRLanguageFile.h
 *   TransnSDK
 *
 *   Created by 姜政 on 2017/8/8.
 *   Copyright © 2018年 Transn. All rights reserved.
 *
 */
#import <Foundation/Foundation.h>

/*!
 *  语种ID，包含国内少数民族语种，不是所有的语种都支持，
 */
typedef NS_ENUM (NSInteger, TRLangIdType) {
    ///中文
    TRLangChina = 1,
    ///英文
    TRLangEnglish = 2,
    ///日语
    TRLangJapanese = 3,
    ///法语
    TRLangFrench = 4,
    ///德语
    TRLangGerman = 5,
    ///俄语
    TRLangRussian = 6,
    ///韩语
    TRLangKorea = 7,
    ///繁体中文
    TRLangTraditionalChinese = 8,
    ///荷兰
    TRLangDutch = 9,
    ///意大利
    TRLangItalian = 10,
    ///西班牙
    TRLangSpanish = 11,
    ///葡萄牙语
    TRLangPortuguese = 12,
    ///阿拉伯语
    TRLangArabic = 13,
    ///土耳其
    TRLangTurkish = 14,
    ///新疆维吾尔语
    TRLangUyghur = 15,
    ///波斯
    TRLangPersian = 16,
    ///蒙语
    TRLangMongolian = 17,
    ///印度尼西亚
    TRLangIndonesian = 18,
    ///马来语
    TRLangMalay = 19,
    ///泰语
    TRLangThai = 20,
    ///越南
    TRLangVietnamese = 21,
    ///老挝
    TRLangLaotian = 22,
    ///印度
    TRLangIndian = 23,
    ///孟加拉
    TRLangBengali = 24,
    ///柬埔寨
    TRLangCambodian = 25,
    ///尼泊尔
    TRLangNepali = 26,
    ///乌克兰
    TRLangUkrainian = 27,
    ///丹麦语
    TRLangDenish = 28,
    ///挪威
    TRLangNorwegian = 29,
    ///芬兰
    TRLangFinnish = 30,
    ///希腊
    TRLangGreek = 31,
    ///波兰
    TRLangPolish = 32,
    ///罗马尼亚
    TRLangRomanian = 33,
    ///保加利亚
    TRLangBulgarian = 34,
    ///捷克
    TRLangCzech = 35,
    ///斯洛伐克
    TRLangSlovak = 36,
    ///匈牙利
    TRLangHungarian = 37,
    ///拉丁语
    TRLangLatin = 38,
    ///希伯莱语
    TRLangRabbinic = 39,
    ///依地语
    TRLangYiddish = 40,
    ///瑞典
    TRLangSwedish = 41,
    ///克罗地亚
    TRLangCroatian = 42,
    ///阿尔巴尼亚
    TRLangAlbanian = 43,
    ///缅甸语
    TRLangMyanmese = 44,
    ///台湾话
    TRLangTaiwan = 45,
    ///香港
    TRLangHongKong = 46,
    ///朝鲜
    TRLangKorean = 47,
    ///菲律宾
    TRLangTagalog = 48,
    ///哈萨克
    TRLangKazakh = 49,
    ///苗语
    TRLangHmong = 50,
    ///高棉语
    TRLangKhmer = 51,
    ///索马里
    TRLangSomali = 52,
    ///塞尔维亚
    TRLangSerbian = 53,
    ///乌兹别克
    TRLangUzbek = 54,
    ///巴西
    TRLangBrazil = 57,
    ///其它
    TRLangOther = 99,
};

@interface TRLanguageFile : NSObject

///通过语种ID获取汉字
+ (NSString *)getLangNameWithLangID:(NSString *)langId;
@end
