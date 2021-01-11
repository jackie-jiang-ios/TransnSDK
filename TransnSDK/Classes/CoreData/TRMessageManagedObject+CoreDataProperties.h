//
//  TRMessageManagedObject+CoreDataProperties.h
//  TransnSDK
//
//  Created by 姜政 on 2020/11/4.
//
//

#import "TRMessageManagedObject+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface TRMessageManagedObject (CoreDataProperties)

+ (NSFetchRequest<TRMessageManagedObject *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSDate *createTime;
@property (nullable, nonatomic, retain) NSData *exMessage;
@property (nullable, nonatomic, copy) NSString *flowId;
@property (nullable, nonatomic, copy) NSString *messageId;
@property (nullable, nonatomic, copy) NSString *translatorId;
@property (nullable, nonatomic, copy) NSString *userId;

@end

NS_ASSUME_NONNULL_END
