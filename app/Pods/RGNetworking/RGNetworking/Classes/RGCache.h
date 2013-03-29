// Copyright 2004-present Facebook. All Rights Reserved.

@interface RGCache : NSObject

/*
 This class is thread safe.
 Objects cached in memory are automatically evicted when memory is low.
 Objects cached on disk are evicted using the LRU scheme when diskCapacity is exceeded.
 Completion blocks are called on a default priority queue.
 */

@property (nonatomic, assign) NSUInteger diskCapacity;
@property (nonatomic, assign) NSUInteger maxObjectCount;

+ (instancetype)sharedCache;

- (id)objectForKey:(NSString *)key;
- (void)objectForKey:(NSString *)key completion:(void(^)(id object))completion;

- (void)setObject:(id)object forKey:(NSString *)key;
- (void)setObject:(id)object forKey:(NSString *)key completion:(void(^)(void))completion;

- (void)removeObjectForKey:(NSString *)key;
- (void)removeAllObjects;

@end
