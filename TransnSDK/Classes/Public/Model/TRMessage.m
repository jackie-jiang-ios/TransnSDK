//
//  TRMessage.m
//  SmallTail
//
//  Created by Fan Lv on 15/9/4.
//  Copyright (c) 2015年 VanRo. All rights reserved.
//

#import "TRMessage.h"
#import "TransnSDK.h"
#import "TransnSDK+Private.h"
#import "XMPPManager.h"
#import "NSXMLElement+XEP_0203.h"
#import "NSObject+TRKeyValue.h"




@implementation TRMessage

@synthesize voiceUrl = _voiceUrl;
@synthesize imageUrl = _imageUrl;
@synthesize voiceSize = _voiceSize;
@synthesize newTranslatedContent = _newTranslatedContent;
@synthesize newContent = _newContent;
@synthesize orginMessageId = _orginMessageId;

- (instancetype)initWithMessage:(XMPPMessage *)xmppMsg
{
    self = [super init];
    
    if (self) {
        _exMessage = xmppMsg;
    }
    
    return self;
}

- (instancetype)initWithWithTextContent:(NSString *)content formUserID:(NSString *)userID
{
    self = [super init];
    
    if (self) {
        _exMessage = [[XMPPMessage alloc] initWithType:@"chat"];
        [_exMessage addBody:content];
        [_exMessage addSubject:XMPP_MessageType_Text];
        [_exMessage addAttributeWithName:@"from" stringValue:userID];
        [_exMessage addAttributeWithName:XMPP_Attribute_MessageID stringValue:[NSString stringWithFormat:@"%u", arc4random()]];
    }
    
    return self;
}

- (instancetype)initWithWithVoiceContent:(NSString *)content formUserID:(NSString *)userID
{
    self = [super init];
    
    if (self) {
        _exMessage = [[XMPPMessage alloc] initWithType:@"chat"];
        [_exMessage addBody:content];
        [_exMessage addSubject:XMPP_MessageType_Voice];
        [_exMessage addAttributeWithName:@"from" stringValue:userID];
        [_exMessage addAttributeWithName:XMPP_Attribute_MessageID stringValue:[NSString stringWithFormat:@"%u", arc4random()]];
    }
    
    return self;
}

- (instancetype)initWithWithImageContent:(NSString *)content formUserID:(NSString *)userID
{
    self = [super init];
    
    if (self) {
        _exMessage = [[XMPPMessage alloc] initWithType:@"chat"];
        [_exMessage addBody:content];
        [_exMessage addSubject:XMPP_MessageType_Image];
        [_exMessage addAttributeWithName:@"from" stringValue:userID];
        [_exMessage addAttributeWithName:XMPP_Attribute_MessageID stringValue:[NSString stringWithFormat:@"%u", arc4random()]];
    }
    
    return self;
}

- (instancetype)initWithWithInfoContent:(NSString *)content formUserID:(NSString *)userID
{
    self = [super init];
    
    if (self) {
        _exMessage = [[XMPPMessage alloc] initWithType:@"chat"];
        [_exMessage addBody:content];
        [_exMessage addSubject:XMPP_MessageType_Info];
        [_exMessage addAttributeWithName:@"from" stringValue:userID];
        [_exMessage addAttributeWithName:XMPP_Attribute_MessageID stringValue:[NSString stringWithFormat:@"%u", arc4random()]];
        _sendState = TIMMessageSendStateSuccess;
    }
    
    return self;
}

- (instancetype)initWithWithNotificationContent:(NSString *)content formUserID:(NSString *)userID
{
    self = [super init];
    
    if (self) {
        _exMessage = [[XMPPMessage alloc] initWithType:@"chat"];
        [_exMessage addBody:content];
        [_exMessage addSubject:XMPP_MessageType_Notification];
        [_exMessage addAttributeWithName:@"from" stringValue:userID];
        [_exMessage addAttributeWithName:XMPP_Attribute_MessageID stringValue:[NSString stringWithFormat:@"%u", arc4random()]];
        _sendState = TIMMessageSendStateSuccess;
    }
    
    return self;
}

- (BOOL)isMyself
{
    NSString    *userID = [[TransnSDK shareManger] myUserID];
    if (!userID) {
        //未登录，表示当前对象是历史消息，用译员对象来判断
        NSString *translatorId =   self.translatorMb.translatorId;
        NSString    *toId = self.exMessage.toStr;
        if([translatorId length]==0){
            TRLog(@"translatorId == nil!!!!!!,%@,%@",self.translatorMb,self.translatorMb.translatorId);
        }else if (translatorId.length>0 && [[translatorId lowercaseString] hasPrefix:[toId lowercaseString]]) {
            return YES;
        }
        return NO;
    }
    NSString    *from = _exMessage.fromStr;
    if (([from length] > 0) && [[from lowercaseString] hasPrefix:[userID lowercaseString]]) {
        return YES;
    }
    
    if ([from length] == 0) {
        [[TransnSDK shareManger] printLog:[NSString stringWithFormat:@"fromId = nil!!!!!! %@",_exMessage]];
    }
    
    return NO;
}

- (TRMessageDirection)messageDirection
{
    if ([self isMyself]) {
        return MessageDirection_SEND;
    } else {
        return MessageDirection_RECEIVE;
    }
}

-(NSString *)formId{
    return self.exMessage.fromStr;
}

-(NSString *)toId{
    return self.exMessage.toStr;
}
- (NSString *)messageID
{
    DDXMLNode *msgID = [_exMessage attributeForName:XMPP_Attribute_MessageID];
    
    return msgID.stringValue;
}

- (NSString *)content
{
    if ([_exMessage.subject isEqualToString:XMPP_MessageType_Text]) {
        return _exMessage.body;
    } else if ([_exMessage.subject isEqualToString:XMPP_MessageType_PaymentMessage]) {
        NSDictionary    *dic = _exMessage.body.tr_JSONObject;
        return [dic objectForKey:@"srcMessageContent"];
    }
    
    return _exMessage.body;
}

- (PaymentMsgType)paymentMessageType
{
    if (self.messageType == TIMMessageTypePaymentMessage) {
        NSDictionary    *dic = _exMessage.body.tr_JSONObject;
        NSString        *paymentSting = dic[@"paymentMessageType"];
        
        if ([paymentSting isEqualToString:@"text2text"]) {
            return PaymentMsgTypeText2Text;
        }
        
        if ([paymentSting isEqualToString:@"text2voice"]) {
            return PaymentMsgTypeText2Voice;
        }
        
        if ([paymentSting isEqualToString:@"voice2text"]) {
            return PaymentMsgTypeVoice2Text;
        }
        
        if ([paymentSting isEqualToString:@"voice2voice"]) {
            return PaymentMsgTypeVoice2Voice;
        }
        
        if ([paymentSting isEqualToString:@"picture2text"]) {
            return PaymentMsgTypeImage2Text;
        }
        
        if ([paymentSting isEqualToString:@"picture2voice"]) {
            return PaymentMsgTypeImage2Voice;
        }
    }
    
    return 0;
}

- (NSString *)imageUrl
{
    if (_imageUrl) {
        return _imageUrl;
    }else if ([_exMessage.subject isEqualToString:XMPP_MessageType_Image]) {
       return _exMessage.body;
    } else if ([_exMessage.subject isEqualToString:XMPP_MessageType_PaymentMessage]) {
        NSDictionary *dic = _exMessage.body.tr_JSONObject;
        return [dic objectForKey:@"srcMessageContent"];
    }
    
    return _imageUrl;
}

- (void)setImageUrl:(NSString *)imageUrl
{
    _imageUrl = imageUrl;
    DDXMLElement *body = [_exMessage elementForName:@"body"];
    [body setStringValue:imageUrl];
}

- (NSString *)voiceUrl
{
    if (_voiceUrl) {
        return _voiceUrl;
    }else if ([_exMessage.subject isEqualToString:XMPP_MessageType_Voice]) {
        if ([[_exMessage.body lowercaseString] hasPrefix:[CustomJsonStr lowercaseString]]) {
            NSString        *infoStr = [_exMessage.body stringByReplacingOccurrencesOfString:CustomJsonStr withString:@""];
            NSDictionary    *dic = infoStr.tr_JSONObject;
            return [dic objectForKey:@"voiceUrl"];
        }
        
        return _exMessage.body;
    } else if (self.messageType == TIMMessageTypePaymentMessage) {
        NSDictionary    *dic = _exMessage.body.tr_JSONObject;
        return [dic objectForKey:@"srcMessageContent"];
    }
    
    return _voiceUrl;
}

- (void)setVoiceUrl:(NSString *)voiceUrl
{
    _voiceUrl = voiceUrl;
    DDXMLElement *body = [_exMessage elementForName:@"body"];
    
    if (voiceUrl.length) {
        NSDictionary    *dict = [NSDictionary dictionaryWithObjectsAndKeys:voiceUrl, @"voiceUrl", _voiceSize, @"voiceSize", nil];
        NSString        *bodySting = [NSString stringWithFormat:@"%@%@", CustomJsonStr,dict.tr_JSONString];
        [body setStringValue:bodySting];
    } else {
        [body setStringValue:voiceUrl];
    }
}

- (void)setVoiceSize:(NSString *)voiceSize
{
    _voiceSize = voiceSize;
    DDXMLElement *body = [_exMessage elementForName:@"body"];
    
    if (voiceSize.length) {
        NSDictionary    *dict = [NSDictionary dictionaryWithObjectsAndKeys:voiceSize, @"voiceSize", _voiceUrl, @"voiceUrl", nil];
        NSString        *bodySting = [NSString stringWithFormat:@"%@%@", CustomJsonStr,dict.tr_JSONString];
        [body setStringValue:bodySting];
    } else {
        [body setStringValue:voiceSize];
    }
}

- (NSString *)voiceSize
{
    if ([_exMessage.subject isEqualToString:XMPP_MessageType_Voice]) {
        if ([[_exMessage.body lowercaseString] hasPrefix:[CustomJsonStr lowercaseString]]) {
            NSString        *infoStr = [_exMessage.body stringByReplacingOccurrencesOfString:CustomJsonStr withString:@""];
            NSDictionary    *dic = infoStr.tr_JSONObject;
            return [dic objectForKey:@"voiceSize"];
        }
        
        return _exMessage.body;
    } else if (self.messageType == TIMMessageTypePaymentMessage) {
        NSDictionary *dic = _exMessage.body.tr_JSONObject;
        return [dic objectForKey:@"srcVoiceTime"];
    }
    
    return _voiceSize;
}

- (NSString *)translateContent
{
    if ([_exMessage.subject isEqualToString:XMPP_MessageType_PaymentMessage]) {
        NSDictionary *dic = _exMessage.body.tr_JSONObject;
        return [dic objectForKey:@"translateContent"];
    }
    
    return _exMessage.body;
}

- (NSString *)translateVoiceUrl
{
    if ([_exMessage.subject isEqualToString:XMPP_MessageType_PaymentMessage]) {
        NSDictionary *dic = _exMessage.body.tr_JSONObject;
        return [dic objectForKey:@"translateContent"];
    }
    if (_translateVoiceUrl) {
        return _translateVoiceUrl;
    }
    return nil;
}

- (NSString *)translateVoiceSize
{
    if (self.messageType == TIMMessageTypePaymentMessage) {
        NSDictionary *dic = _exMessage.body.tr_JSONObject;
        return [dic objectForKey:@"translateVoiceTime"];
    }
    if (_translateVoiceSize) {
       return _translateVoiceSize;
    }
    return @"";
}

- (int)lensCount
{
    if (self.messageType == TIMMessageTypePaymentMessage) {
        NSDictionary *dic = _exMessage.body.tr_JSONObject;
        return [[dic objectForKey:@"lensCount"] intValue];
    }
    
    return 0;
}

-(NSString *)orginMessageId{
    if (self.messageType == TIMMessageTypePaymentMessage) {
        NSDictionary *dic = _exMessage.body.tr_JSONObject;
        return [dic objectForKey:@"orginMessageId"];
    }
    return nil;
}
// - (UIImage *)image
// {
//    if (_image == nil && [_exMessage.subject isEqualToString:XMPP_MessageType_Image])
//    {
//        DDXMLElement *attachment = [self.exMessage elementForName:@"attachment"];
//        NSData *data = [[NSData alloc] initWithBase64EncodedString:[attachment stringValue] options:0];
//        UIImage *image = [[UIImage alloc] initWithData:data];
//        _image  = image;
//
//    }
//    return _image;
// }

- (TransnIMMessageType)messageType
{
    if ([_exMessage.subject isEqualToString:XMPP_MessageType_Image]) {
        return TIMMessageTypeImage;
    } else if ([_exMessage.subject isEqualToString:XMPP_MessageType_Tip]) {
        return TIMMessageTypeTips;
    } else if ([_exMessage.subject isEqualToString:XMPP_MessageType_Notification]) {
        return TIMMessageTypeNotification;
    } else if ([_exMessage.subject isEqualToString:XMPP_MessageType_Info]) {
        return TIMMessageTypeInfo;
    } else if ([_exMessage.subject isEqualToString:XMPP_MessageType_Voice]) {
        return TIMMessageTypeVocie;
    } else if ([_exMessage.subject isEqualToString:XMPP_MessageType_PaymentMessage]) {
        return TIMMessageTypePaymentMessage;
    } else if ([_exMessage.subject isEqualToString:XMPP_MessageType_RecommendMessage]) {
        return TIMMessageTypeRecommandMessage;
    } else {
        return TIMMessageTypeText;
    }
}

- (NSString *)newContent
{
    if (self.sensitiveWords.count == 0) {
        return self.content;
    }
    
    if (_newContent) {
        return _newContent;
    }
    
    if (self.content.length == 0) {
        return self.content;
    }
    
    NSString *newContent = [NSString stringWithString:self.content];
    
    // *译员端对于敏感词不用*号代替 只显示高亮
    for (NSDictionary *dict in self.sensitiveWords) {
        NSString *sensitiveLevel = dict[@"sensitiveLevel"];
        
        // 1级敏感词 文字直接用**代替
        if ([sensitiveLevel isEqualToString:@"1"]) {
            NSArray *sensitiveWords = dict[@"sensitiveWords"];
            
            for (NSString *word in sensitiveWords) {
                NSMutableString *starString = [[NSMutableString alloc] initWithString:@""];
                
                for (int i = 0; i < word.length; i++) {
                    [starString appendString:@"*"];
                }
                
                newContent = [newContent stringByReplacingOccurrencesOfString:word withString:starString];
            }
        }
    }
    
    // */
    _newContent = newContent;
    return newContent;
}

- (NSString *)newTranslatedContent
{
    if (self.sensitiveWords.count == 0) {
        return self.translateContent;
    }
    
    if (_newTranslatedContent) {
        return _newTranslatedContent;
    }
    
    if (self.translateContent.length == 0) {
        return self.translateContent;
    }
    
    NSString *newContent = [NSString stringWithString:self.translateContent];
    
    // *译员端对于敏感词不用*号代替 只显示高亮
    for (NSDictionary *dict in self.sensitiveWords) {
        NSString *sensitiveLevel = dict[@"sensitiveLevel"];
        
        // 1级敏感词 文字直接用**代替
        if ([sensitiveLevel isEqualToString:@"1"]) {
            NSArray *sensitiveWords = dict[@"sensitiveWords"];
            
            for (NSString *word in sensitiveWords) {
                NSMutableString *starString = [[NSMutableString alloc] initWithString:@""];
                
                for (int i = 0; i < word.length; i++) {
                    [starString appendString:@"*"];
                }
                
                newContent = [newContent stringByReplacingOccurrencesOfString:word withString:starString];
            }
        }
    }
    
    // */
    _newTranslatedContent = newContent;
    return newContent;
}

- (BOOL)isHaveSensitiveWords
{
    for (NSDictionary *dict in self.sensitiveWords) {
        NSString *sensitiveLevel = dict[@"sensitiveLevel"];
        
        if ([sensitiveLevel isEqualToString:@"1"] || [sensitiveLevel isEqualToString:@"2"]) {
            NSArray *sensitiveWords = dict[@"sensitiveWords"];
            
            for (NSString *word in sensitiveWords) {
                if (([self.content rangeOfString:word].location != NSNotFound) || ([self.translateContent rangeOfString:word].location != NSNotFound)) {
                    return YES;
                }
            }
        }
    }
    
    return NO;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    //存储主要的，可能有变数的，节约性能
    [coder encodeObject:_exMessage forKey:@"exMessage"];
    [coder encodeInt:_sendState forKey:@"sendState"];
    [coder encodeObject:_timestamp forKey:@"timestamp"];
    [coder encodeObject:_sensitiveWords forKey:@"sensitiveWords"];
  
    [coder encodeObject:_imageUrl forKey:@"imageUrl"];
     [coder encodeObject:_voiceSize forKey:@"voiceSize"];
     [coder encodeObject:_voiceUrl forKey:@"voiceUrl"];
    [coder encodeObject:_voicelocalUrl forKey:@"voicelocalUrl"];
    //translateImage\translateImageUrl无用属性
    [coder encodeObject:_translateVoiceSize forKey:@"translateVoiceSize"];
    [coder encodeObject:_translateVoiceUrl forKey:@"translateVoiceUrl"];
     //translateVoiceLocalUrl无用属性

    if (self.imageUrl.length) {
        //不要随意存储，有内存消耗
//     TRLog(@"图片没有存储:%@,%@",self.imageUrl,self.image);
    }else{
        [coder encodeObject:_image forKey:@"image"];
    }
    [coder encodeObject:_translatorMb forKey:@"translatorMb"];
    [coder encodeObject:@(_lensCount) forKey:@"lensCount"];
    if ([_exMessage.subject isEqualToString:XMPP_MessageType_PaymentMessage]) {
        [coder encodeObject:_orginMessageId forKey:@"orginMessageId"];
    }
    
}

- (id)initWithCoder:(NSCoder *)coder
{
    if (self = [super init]) {
        _exMessage = [coder decodeObjectForKey:@"exMessage"];
        _sendState = [coder decodeIntForKey:@"sendState"];
        _timestamp = [coder decodeObjectForKey:@"msgDate"];
        _sensitiveWords = [coder decodeObjectForKey:@"sensitiveWords"];
        _imageUrl = [coder decodeObjectForKey:@"imageUrl"];
        _voiceSize = [coder decodeObjectForKey:@"voiceSize"];
        _voiceUrl = [coder decodeObjectForKey:@"voiceUrl"];
        _voicelocalUrl = [coder decodeObjectForKey:@"voicelocalUrl"];
        //translateImage\translateImageUrl无用属性
        _translateVoiceSize = [coder decodeObjectForKey:@"translateVoiceSize"];
        _translateVoiceUrl = [coder decodeObjectForKey:@"translateVoiceUrl"];
        //translateVoiceLocalUrl无用属性
        if (self.imageUrl.length) {
           //不要随意返回，有内存消耗
        }else{
            _image = [coder decodeObjectForKey:@"image"];
        }
        _lensCount = [[coder decodeObjectForKey:@"lensCount"] intValue];
        _translatorMb = [coder decodeObjectForKey:@"translatorMb"];
        if ([_exMessage.subject isEqualToString:XMPP_MessageType_PaymentMessage]) {
            [coder decodeObjectForKey:@"_rginMessageId"];
        }
    }
    
    return self;
}

@end
