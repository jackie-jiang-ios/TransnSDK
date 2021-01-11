//
//  MagicalRecord+Transn.h
//  CocoaAsyncSocket
//
//  Created by 姜政 on 2020/12/10.
//
#import <MagicalRecord/MagicalRecord.h>



NS_ASSUME_NONNULL_BEGIN
@interface MagicalRecord (Transn)

+ (void) setTransnDefaultModelFromClass:(Class)modelClass;

@end

NS_ASSUME_NONNULL_END
