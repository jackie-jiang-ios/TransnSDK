
#import "TRSafeJSON.h"

@interface TRSafeJSON()

- (BOOL)isthisADirtyObject:(id)anObject;
- (BOOL)isThisObjectACollection:(NSObject *)anObject;
- (NSObject *)cleanUpCollection:(NSObject *)aCollection;
@end

@implementation TRSafeJSON

- (id)cleanUpJson:(id)JSON
{
    if (!JSON) return nil;
    if ([JSON isKindOfClass:[NSNull class]]) return nil;
    id cleanJSON = [self cleanUpCollection:JSON];
    return cleanJSON;
}

- (NSArray *)cleanUpArray:(NSArray *)anArray
{
    NSEnumerator *enumerator = [anArray objectEnumerator];
    NSMutableArray *mutableArray = [NSMutableArray new];
    NSObject *object;
    
    while (object = [enumerator nextObject])
    {
        if ([self isThisObjectACollection:object])
            object = [self cleanUpCollection:object];
        if (![self isthisADirtyObject:object])
            [mutableArray addObject:object];
    }
    return mutableArray;
}

- (NSDictionary *)cleanUpDictionary:(NSDictionary *)aDictionary
{
    NSMutableDictionary *mutableDico = [NSMutableDictionary new];
    NSArray *keys = [aDictionary allKeys];
    for (NSString *key in keys)
    {
        NSObject *object = [aDictionary objectForKey:key];
        if ([self isThisObjectACollection:object])
            object = [self cleanUpCollection:object];
        if (![self isthisADirtyObject:object])
            [mutableDico setObject:object forKey:key];
    }
    return mutableDico;
}

- (NSObject *)cleanUpCollection:(NSObject *)aCollection
{    
    if ([aCollection isKindOfClass:[NSArray class]])
        return [self cleanUpArray:(NSArray *)aCollection];
    return [self cleanUpDictionary:(NSDictionary *)aCollection];
}

- (BOOL)isThisObjectACollection:(NSObject *)anObject;
{
    if ([anObject isKindOfClass:[NSDictionary class]]) return YES;
    
    if ([anObject isKindOfClass:[NSArray class]]) return YES;
    
    return NO;
}

- (BOOL)isthisADirtyObject:(id)anObject;
{
    if ([anObject isKindOfClass:[NSString class]]) {
        NSString *aString = anObject;
        if ([aString isEqualToString:@""]) return YES;
    }
    if ([anObject isKindOfClass:[NSNull class]]) return YES;
    return NO;
}

@end
