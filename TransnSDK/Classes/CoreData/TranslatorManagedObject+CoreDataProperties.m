//
//  TranslatorManagedObject+CoreDataProperties.m
//  TransnSDK
//
//  Created by 姜政 on 2020/11/4.
//
//

#import "TranslatorManagedObject+CoreDataProperties.h"

@implementation TranslatorManagedObject (CoreDataProperties)

+ (NSFetchRequest<TranslatorManagedObject *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"TranslatorManagedObject"];
}

@dynamic transerInfo;
@dynamic translatorIcon;
@dynamic translatorId;
@dynamic translatorName;

@end
