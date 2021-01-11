//
//  MagicalRecord+Transn.m
//  CocoaAsyncSocket
//
//  Created by 姜政 on 2020/12/10.
//

#import "MagicalRecord+Transn.h"

@implementation MagicalRecord (Transn)

+ (void) setTransnDefaultModelFromClass:(Class)modelClass{
        NSString *path  = [[NSBundle bundleForClass:modelClass] pathForResource:@"TransnSDK" ofType:@"bundle"];
    //    NSBundle *bundle = [NSBundle bundleForClass:modelClass];
        NSBundle *bundle = [NSBundle bundleWithPath:path];
     //   NSLog(@"重要bundle:%@",bundle);
        NSManagedObjectModel *model = [NSManagedObjectModel mergedModelFromBundles:[NSArray arrayWithObject:bundle]];
        [NSManagedObjectModel MR_setDefaultManagedObjectModel:model];
}
@end
