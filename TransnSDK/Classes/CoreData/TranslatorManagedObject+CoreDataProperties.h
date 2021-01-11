//
//  TranslatorManagedObject+CoreDataProperties.h
//  TransnSDK
//
//  Created by 姜政 on 2020/11/4.
//
//

#import "TranslatorManagedObject+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface TranslatorManagedObject (CoreDataProperties)

+ (NSFetchRequest<TranslatorManagedObject *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *transerInfo;
@property (nullable, nonatomic, copy) NSString *translatorIcon;
@property (nullable, nonatomic, copy) NSString *translatorId;
@property (nullable, nonatomic, copy) NSString *translatorName;

@end

NS_ASSUME_NONNULL_END
