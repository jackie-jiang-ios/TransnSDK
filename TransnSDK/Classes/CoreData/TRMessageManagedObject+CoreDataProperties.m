//
//  TRMessageManagedObject+CoreDataProperties.m
//  TransnSDK
//
//  Created by 姜政 on 2020/11/4.
//
//

#import "TRMessageManagedObject+CoreDataProperties.h"

@implementation TRMessageManagedObject (CoreDataProperties)

+ (NSFetchRequest<TRMessageManagedObject *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"TRMessageManagedObject"];
}

@dynamic createTime;
@dynamic exMessage;
@dynamic flowId;
@dynamic messageId;
@dynamic translatorId;
@dynamic userId;

@end
