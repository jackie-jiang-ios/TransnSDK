//
//  TRTranslator.m
//  TransnSDK
//
//  Created by 姜政 on 2017/11/19.
//  Copyright © 2017年 Transn. All rights reserved.
//

#import "TRTranslator.h"
#import "NSManagedObject+TExtension.h"

@implementation TRTranslator

@synthesize  translatorName = _translatorName;
@synthesize  transerInfo = _transerInfo;
@synthesize  translatorId = _translatorId;
@synthesize  translatorIcon = _translatorIcon;

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:_translatorId forKey:@"translatorId"];
    [coder encodeObject:_transerInfo forKey:@"transerInfo"];
    [coder encodeObject:_translatorIcon forKey:@"translatorIcon"];
    [coder encodeObject:_translatorName forKey:@"translatorName"];
}

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    
    if (self) {
        _translatorId = [coder decodeObjectForKey:@"translatorId"];
        _transerInfo = [coder decodeObjectForKey:@"transerInfo"];
        _translatorIcon = [coder decodeObjectForKey:@"translatorIcon"];
        _translatorName = [coder decodeObjectForKey:@"translatorName"];
    }
    
    return self;
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key
{
    if ([key isEqualToString:@"translatorRemark"]) {
        self.transerInfo = value;
    } else if ([key isEqualToString:@"userid"]) {
        self.translatorId = value;
    } else if ([key isEqualToString:@"userName"]) {
        self.translatorName = value;
    } else if ([key isEqualToString:@"image"]) {
        self.translatorIcon = value;
    }
}

+ (TRTranslator *)managedObjectWithTranslatorId:(NSString *)translatorId
{
    TranslatorManagedObject *translatorMb = [TranslatorManagedObject managedObjectWithTranslatorId:translatorId];
    
    if (translatorMb) {
        TRTranslator *tr = [[TRTranslator alloc] init];
        tr.translatorIcon = translatorMb.translatorIcon;
        tr.translatorName = translatorMb.translatorName;
        tr.transerInfo = translatorMb.transerInfo;
        tr.translatorId = translatorMb.translatorId;
        return tr;
    } else {
        return nil;
    }
}

+ (void)insertItemWithDict:(NSDictionary *_Nullable)dict
{
    [TranslatorManagedObject insertItemWithDict:dict];
}

@end
