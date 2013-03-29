//  Copyright 2013-present Ryan Gomba. All rights reserved.

#define RGKeypath(object, keyPath) \
@(((void)(NO && ((void)object.keyPath, NO)), # keyPath))

typedef void (^RGKVOBlock) (NSDictionary *change);
typedef void (^RGSimpleKVOBlock) (id value);

#define RGObserver(object, keyPath) \
[[RGKVOObserver alloc] initWithObject:object keypath:RGKeypath(object, keyPath)]

@class RGKVOHandle;
@interface RGKVOObserver : NSObject

- (id)initWithObject:(id)object keypath:(NSString*)keypath;

- (RGKVOHandle *)observe:(RGSimpleKVOBlock)block;
- (RGKVOHandle *)observe:(RGSimpleKVOBlock)block queue:(dispatch_queue_t)queue;
- (RGKVOHandle *)observeOnMain:(RGSimpleKVOBlock)block;

- (RGKVOHandle *)observe:(RGKVOBlock)block options:(NSKeyValueObservingOptions)options;
- (RGKVOHandle *)observe:(RGKVOBlock)block options:(NSKeyValueObservingOptions)options queue:(dispatch_queue_t)queue;
- (RGKVOHandle *)observeOnMain:(RGKVOBlock)block options:(NSKeyValueObservingOptions)options;

@end

@interface RGKVOHandle : NSObject

- (void)stopObserving;

@end
