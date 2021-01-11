//
//  TRReservationManager.m
//  TransnSDK
//
//  Created by 姜政 on 2018/4/20.
//  Copyright © 2018年 Transn. All rights reserved.
//

#import "TRReservationManager.h"
#import "TRError.h"
#import "TRFileLog.h"
#import "TransnSDK+Private.h"
#import "TRReservation.h"
#import "TRPrivateConstants.h"
#import "TRConstants.h"
#import "TRNetWork.h"
#import "TRBaseModel.h"
#import "XMPPManager.h"
#import "NSDate+TRExtension.h"


@implementation TRReservationManager

/**
 *  预约单上传文件获取文件ID
 *  @param translateObject  需要翻译的内容
 *  @param completion   回调
 */
-(void)upLoadFile:(TRFileObject *)translateObject
     completetion:(TIMCompletionBlock)completion{
    if (![TransnSDK shareManger].isLoginSDK) {
        [TRError unLoginError:completion];
        return;
    } if(translateObject.fileUrl.length&&translateObject.fileId.length&&translateObject.count.length&&translateObject.srcLanguageId.length) {
        //拿到fileId了
        completion(translateObject,nil);
        return;
    }
    [self requestTranslateObjectUrl:translateObject completetion:^(id result, NSError *error) {
        if (error) {
            if (completion) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(nil,error);
                });
            }
        }else{
            NSDictionary *dic = TRDicWithOAndK(translateObject.fileName,@"fileName", translateObject.fileUrl,@"fileUrl",translateObject.type==TRFileObjectTypeText?@"txt":@"jpg",@"fileType");
            [[TRNetWork sharedManager] requestURLPath:ST_API_file_upload httpMethod:TRRequestMethodPost parmas:dic completetion:^(id responseObject, NSError *error) {
                TRBaseModel *model = [[TRBaseModel alloc] initWithDictionary:responseObject];
                if (model.isStatusOK) {
                    translateObject.fileId = [NSString stringWithFormat:@"%@",model.data[@"fileId"]];
                    translateObject.count = [NSString stringWithFormat:@"%@",model.data[@"wordCount"]];
                    translateObject.recognizerLangId = [NSString stringWithFormat:@"%@",model.data[@"langId"]];
                    translateObject.isStat = [model.data[@"isStat"] boolValue];
                    if (completion) {
                        completion(translateObject,nil);
                    }
                } else {
                    [TRError errorWithCode:10002 description:@"获取文件FileId失败" completion:completion];
                }
            }];
          
        }
    }];
}
/**
 *  预约单订单预估时长
 *  @param translateObject  需要翻译的内容
 *  @param completion   回调
 */
-(void)estimateFile:(NSArray<TRFileObject*> *)translateObjects
       completetion:(TIMCompletionBlock)completion{
    if (![TransnSDK shareManger].isLoginSDK) {
        [TRError unLoginError:completion];
        return;
    }
    if (translateObjects.count==0) {
        [TRError paramError:@"translateObjects" completion:completion];
        return;
    }
  
        BOOL isRet = YES;
        NSString *paramName = @"";
        TRFileObject *object = translateObjects[0];
        for (NSInteger i=0; i<translateObjects.count; i++) {
            TRFileObject *eveObject = translateObjects[i];
            isRet = [self checkParam:eveObject];
            if (isRet==NO) {
                paramName = [NSString stringWithFormat:@"第%@个translateObject",@(i+1)];
                break;
            }
            if (object.translatorId||eveObject.translatorId) {
                if ([object.translatorId isEqualToString:eveObject.translatorId]) {
                    
                }else{
                    isRet = NO;
                    paramName = [NSString stringWithFormat:@"第%@个translateObject的translatorId",@(i+1)];
                    break;
                }
            }
            
           
            if ([object.srcLanguageId isEqualToString:eveObject.srcLanguageId]&&[object.tarLanguageId isEqualToString:eveObject.tarLanguageId]) {

            }else{
                isRet = NO;
                paramName = [NSString stringWithFormat:@"第%@个translateObject的srcLanguageId或者tarLanguageId",@(i+1)];
                break;
            }
        }
    if (!isRet) {
        [TRError paramError:paramName completion:completion];
        return ;
    }
    [self getFileID:translateObjects completetion:^(NSArray *fileIds, NSError *error) {
                if (error) {
                    if (completion) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            completion(nil,error);
                        });
                    }
                }else{
//                去预估
                   NSDictionary *dic = TRDicWithOAndK([fileIds componentsJoinedByString:@","],@"files", object.srcLanguageId ,@"srcLanguageId",object.tarLanguageId,@"tarLanguageId");
                    NSMutableDictionary *parmas = [dic mutableCopy];
                    if (object.translatorId) {
                        [parmas setObject:object.translatorId forKey:@"translatorId"];
                    }
                    [[TRNetWork sharedManager] requestURLPath:ST_API_morder_getQuote httpMethod:TRRequestMethodPost parmas:dic completetion:^(id responseObject, NSError *error) {
                        TRBaseModel *model = [[TRBaseModel alloc] initWithDictionary:responseObject];
                        if (model.isStatusOK) {
                            if (completion) {
                                TRReservation *reservation = [[TRReservation alloc] init];
                                reservation.translateObjects = translateObjects;
                                reservation.count = model.data[@"count"];
                                reservation.minutes = model.data[@"minutes"];
                                completion(reservation,nil);
                            }
                        } else {
                            [TRError errorWithCode:10004 description:@"预估价格失败" completion:completion];
                        }
                    }];
                }
            }];
}
-(void)getFileID:(NSArray<TRFileObject*> *)translateObjects
    completetion:(void (^)(NSArray *fileIds,NSError *error))completion{
   __block NSMutableArray *translateErrors= [[NSMutableArray alloc] initWithCapacity:translateObjects.count];
    __block NSMutableArray *rightTranslateFileIDs = [[NSMutableArray alloc] initWithCapacity:translateObjects.count];
    for (NSInteger i=0; i<translateObjects.count; i++) {
        TRFileObject *currentObject  = translateObjects[i];
        [self upLoadFile:currentObject completetion:^(TRFileObject *translateObject, NSError *error) {
            if (error) {
                [translateErrors addObject:error];
            }else{
                [rightTranslateFileIDs addObject:translateObject.fileId];
            }
            if (translateErrors.count+rightTranslateFileIDs.count==translateObjects.count) {
                if (completion) {
                    if (translateErrors.count>0) {
                       NSError *error2 = [TRError errorWithDomain:@"" code:10002 description:@"有文件获取fileID失败"];
                        dispatch_async(dispatch_get_main_queue(), ^{
                             completion(rightTranslateFileIDs,error2);
                        });
                    }else{
                        completion(rightTranslateFileIDs,nil);
                    }
                }
            }
        }];
    }
}

//检查参数
-(BOOL)checkParam:(TRFileObject *)translateObject{
    if (translateObject.srcLanguageId.length==0||translateObject.tarLanguageId.length==0) {
//        NSLog(@"%s,%d",__func__,__LINE__);
        return NO;
    }
    if (translateObject.srcText.length||translateObject.srcImage||translateObject.fileUrl.length||translateObject.fileId.length) {
        if (translateObject.type==TRFileObjectTypeText) {
            if (translateObject.srcText.length==0) {
                return NO;
            }else{
                return YES;
            }
        }
        if (translateObject.type== TRFileObjectTypeImage) {
            if (translateObject.fileUrl.length==0&&translateObject.srcImage==nil) {
                return NO;
            }else{
                return YES;
            }
        }
        return NO;
    }else{
        return NO;
    }
}

/**
 *  预约单下单
 *  @param reservation 预约单对象，TRReservation.TRFileObjects对象必须已经获取了fileId，并且它们的原语种和目标语种的ID必须一样
 *  @param completion   回调
 */
-(void)submitReservation:(TRReservation *)reservation
            completetion:(void (^)(TRReservation *reservation,NSError *error))completion{
    if (![TransnSDK shareManger].isLoginSDK) {
        [TRError unLoginError:completion];
        return;
    }
    if (reservation.translateObjects.count==0) {
        [TRError paramError:completion];
        return ;
    }

        BOOL isRet = YES;
        TRFileObject *object = reservation.translateObjects[0];
       
        for (NSInteger i=0; i<reservation.translateObjects.count; i++) {
            TRFileObject *eveObject = reservation.translateObjects[i];
            if (!eveObject.fileId||![object.srcLanguageId isEqualToString:eveObject.srcLanguageId]||![object.tarLanguageId isEqualToString:eveObject.tarLanguageId]) {
                isRet = NO;
                break;
            }
        }
        if (object.srcLanguageId.length==0||object.tarLanguageId.length==0) {
            isRet = NO;
        }
        if (!isRet) {
            [TRError paramError:completion];
            return ;
        }
        //去下单
            [self getFileID:reservation.translateObjects completetion:^(NSArray *fileIds, NSError *error) {
                if (error) {
                    if (completion) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            completion(nil,error);
                        });
                    }
                }else{
                    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
                    if (reservation.sourceId) {
                          [params setObject:reservation.sourceId forKey:@"sourceId"];
                    }else{
                        [TRError paramError:completion];
                        return ;
                    }
                    if (reservation.userId) {
                        [params setObject:reservation.userId forKey:@"userId"];
                    }else{
                        [TRError paramError:completion];
                        return ;
                    }
                  
                    if (reservation.translatorId) {
                        [params setObject:reservation.translatorId forKey:@"translatorId"];
                    }
                    
                    [params setObject:object.srcLanguageId forKey:@"srcLanguageId"];
                    [params setObject:object.tarLanguageId forKey:@"tarLanguageId"];
                    [params setObject:[fileIds componentsJoinedByString:@","] forKey:@"files"];
                    if (reservation.remark) {
                        [params setObject:reservation.remark forKey:@"remark"];
                    }
                    if (reservation.callbackType) {
                        [params setObject:@(reservation.callbackType) forKey:@"callbackType"];
                    }
                    if (reservation.callback) {
                          [params setObject:reservation.callback forKey:@"callback"];
                    }else{
                        [TRError paramError:completion];
                        return ;
                    }
                    if (reservation.bizResult) {
                        [params setObject:reservation.bizResult forKey:@"bizResult"];
                    }
                    [[TRNetWork sharedManager] requestURLPath:ST_API_morder_create httpMethod:TRRequestMethodPost parmas:params completetion:^(id responseObject, NSError *error) {
                        if (error) {
                            if (completion) {
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    completion(nil,error);
                                });
                            }
                        }else{
                            TRBaseModel *model = [[TRBaseModel alloc] initWithDictionary:responseObject];
                            if (model.isStatusOK) {
                                if (completion) {
                                    reservation.orderId = model.data[@"orderId"];
                                    completion(reservation,nil);
                                }
                            } else {
                                [TRError errorWithCode:10003 description:model.msg completion:completion];
                            }
                        }
                    }];
                }
            }];
}

#pragma mark 文件相关
//上传文件
-(void)requestTranslateObjectUrl:(TRFileObject *)translateObject
                    completetion:(TIMCompletionBlock)completion{
    if (translateObject.fileUrl.length) {
        if (completion) {
            completion(translateObject,nil);
        }
    }else{
        [self getFile:translateObject Data:^(NSData *data, NSString *extention, NSError *error) {
            if (error) {
                if (completion) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                         completion(nil,error);
                    });
                }
            }else{
                if (translateObject.fileName) {

                }else{
                    NSString *dateStr =   [NSDate currentDate:@"YYYYMMddHHmmssSSS"];
                    translateObject.fileName = [NSString stringWithFormat:@"%@_%@.%@", [TransnSDK shareManger].myUserID,dateStr, extention];
                }
                [[TransnSDK shareManger] uploadData:data fileName:translateObject.fileName withExtention:extention completionHandler:^(NSString *fileUrl, NSError *error) {
                    if (error) {
                        if (completion) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                completion(nil,error);
                            });
                        }
                    }else{
                        //去预估下单
                        translateObject.srcImage = nil;
                        translateObject.fileUrl = fileUrl;
                        if (completion) {
                            completion(translateObject,nil);
                        }
                    }
                }];
            }
        }];
    }
}

//获取文件data
-(void)getFile:(TRFileObject *)object Data:(void (^)(NSData *data,NSString* extention,NSError *error))completion{
    if (!completion) {
        return;
    }
    if (object.srcText.length) {
        object.type = TRFileObjectTypeText;
    }else if(object.srcImage){
        object.type = TRFileObjectTypeImage;
    }else{
        dispatch_async(dispatch_get_main_queue(), ^{
             completion(nil,nil,[TRError errorWithDomain:nil code:9990 description:@"参数错误"]);
        });
    }
    
    if (object.type == TRFileObjectTypeText) {
        [[TRFileLog sharedManager] writeContent:object.srcText toFilePath:nil success:^(BOOL success,NSString *filePath) {
            if (success) {
                NSData      *filedata = [NSData dataWithContentsOfFile:filePath];
                completion(filedata,@"txt",nil);
            }else{
                dispatch_async(dispatch_get_main_queue(), ^{
                       completion(nil,nil,[TRError errorWithDomain:nil code:10000 description:@"生成txt文件失败"]);
                });
            }
        }];
    }else{
        completion(UIImageJPEGRepresentation(object.srcImage, 1.0),@"jpg",nil);
    }
}


-(void)leaveMessage:(NSString *)content  sourceId:(NSString *)sourceId completetion:(TIMCompletionBlock)completion{
    if (content==nil||sourceId==nil) {
        [TRError paramError:completion];
    }else{
        [[TRNetWork sharedManager] requestURLPath:ST_API_morder_createMessage  httpMethod:TRRequestMethodPost parmas:@{@"sourceId":sourceId,@"content":content,@"type":@"text"} completetion:^(id responseObject, NSError *error) {
            if (error) {
                if (completion) {
                    completion(nil,error);
                }
            }else{
                TRBaseModel *model = [[TRBaseModel alloc] initWithDictionary:responseObject];
                if (model.isStatusOK) {
                    if (completion) {
                        completion(@1,nil);
                    }
                } else {
                    [TRError errorWithCode:10005 description:model.msg completion:completion];
                }
            }
        }];
    }
}

-(void)leaveImageMessage:(UIImage *)image  sourceId:(NSString *)sourceId completetion:(TIMCompletionBlock)completion{
    if (image==nil||sourceId==nil) {
        [TRError paramError:completion];
    }else{
        [[TransnSDK shareManger] uploadData:UIImageJPEGRepresentation(image, 1.0f) fileName:nil withExtention:@"jpg" completionHandler:^(NSString *fileUrl, NSError *error) {
            //去预估下单
            if (error) {
                if (completion) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        completion(nil,error);
                    });
                }
            }else{
                [[TRNetWork sharedManager] requestURLPath:ST_API_morder_createMessage  httpMethod:TRRequestMethodPost parmas:@{@"sourceId":sourceId,@"content":fileUrl,@"type":@"pic"} completetion:^(id responseObject, NSError *error) {
                    if (error) {
                        if (completion) {
                            completion(nil,error);
                        }
                    }else{
                        TRBaseModel *model = [[TRBaseModel alloc] initWithDictionary:responseObject];
                        if (model.isStatusOK) {
                            if (completion) {
                                completion(@1,nil);
                            }
                        } else {
                            [TRError errorWithCode:10005 description:model.msg completion:completion];
                        }
                    }
                }];
            }
        }];
      
    }
}
@end
