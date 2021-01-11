//
//  TRLanguageFile.m
//  TransnSDK
//
//  Created by 姜政 on 2017/8/8.
//  Copyright © 2017年 Transn. All rights reserved.
//

#import "TRLanguageFile.h"

@implementation TRLanguageFile

+ (NSString *)getLangNameWithLangID:(NSString *)langId
{
    NSArray *list = [[NSUserDefaults standardUserDefaults] valueForKey:@"LanguageList"];
    
    if (list && list.count) {
        for (NSDictionary *dict in list) {
            NSString    *lanid = dict[@"langId"];
            NSString    *lanName = dict[@"langName"];
            
            if ([langId isEqualToString:lanid]) {
                return lanName;
            }
        }
    }
    
    TRLangIdType  type = (TRLangIdType)[langId intValue];
    NSString    *langString = @"";
    switch (type) {
        case TRLangChina:
            langString = NSLocalizedString(@"中文", @"中文");
            break;
            
        case TRLangEnglish:
            langString = NSLocalizedString(@"英语", @"英语");
            break;
            
        case TRLangJapanese:
            langString = NSLocalizedString(@"日语", @"日语");
            break;
            
        case TRLangFrench:
            langString = NSLocalizedString(@"法语", @"法语");
            break;
            
        case TRLangGerman:
            langString = NSLocalizedString(@"德语", @"德语");
            break;
            
        case TRLangRussian:
            langString = NSLocalizedString(@"俄语", @"俄语");
            break;
            
        case TRLangKorea:
            langString = NSLocalizedString(@"韩语", @"韩语");
            break;
            
        case TRLangItalian:
            langString = NSLocalizedString(@"意大利语", @"意大利语");
            break;
            
        case TRLangSpanish:
            langString = NSLocalizedString(@"西班牙语", @"西班牙语");
            break;
            
        case TRLangPortuguese:
            langString = NSLocalizedString(@"葡萄牙语", @"葡萄牙语");
            break;
            
        case TRLangArabic:
            langString = NSLocalizedString(@"阿拉伯语", @"阿拉伯语");
            break;
            
        case TRLangThai:
            langString = NSLocalizedString(@"泰语", @"泰语");
            break;
            
        case TRLangCzech:
            langString = NSLocalizedString(@"捷克语", @"捷克语");
            break;
            
        case TRLangDenish:
            langString = NSLocalizedString(@"丹麦语", @"丹麦语");
            break;
            
        case TRLangDutch:
            langString = NSLocalizedString(@"荷兰语", @"荷兰语");
            break;
            
        case TRLangFinnish:
            langString = NSLocalizedString(@"芬兰语", @"芬兰语");
            break;
            
        case TRLangRabbinic:
            langString = NSLocalizedString(@"希伯莱语", @"希伯莱语");
            break;
            
        case TRLangIndonesian:
            langString = NSLocalizedString(@"印尼语", @"印尼语");
            break;
            
        case TRLangHungarian:
            langString = NSLocalizedString(@"匈牙利语", @"匈牙利语");
            break;
            
        case TRLangNorwegian:
            langString = NSLocalizedString(@"挪威语", @"挪威语");
            break;
            
        case TRLangPolish:
            langString = NSLocalizedString(@"波兰语", @"波兰语");
            break;
            
        case TRLangSwedish:
            langString = NSLocalizedString(@"瑞典语", @"瑞典语");
            break;
            
        case TRLangTurkish:
            langString = NSLocalizedString(@"土耳其语", @"土耳其语");
            break;
            
        case TRLangVietnamese:
            langString = NSLocalizedString(@"越南语", @"越南语");
            break;
            
        case TRLangUkrainian:
            langString = NSLocalizedString(@"乌克兰语", @"乌克兰语");
            break;
            
        case TRLangMalay:
            langString = NSLocalizedString(@"马来语", @"马来语");
            break;
            
        case TRLangIndian:// 23 印度语
            langString = NSLocalizedString(@"印度语", @"印度语");
            break;
            
        default:
            langString = @"";
            break;
    }
    
    return langString;
}

@end
