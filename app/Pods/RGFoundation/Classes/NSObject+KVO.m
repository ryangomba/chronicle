//  Copyright 2013-present Ryan Gomba. All rights reserved.

#import "NSObject+KVO.h"

@interface RGKVOHandle () {
    BOOL _stoppedObserving;
}

@property (nonatomic, copy) RGKVOBlock block;
@property (nonatomic, weak) id object;
@property (nonatomic, copy) NSString *keyPath;

@end


@implementation RGKVOHandle

- (void)dealloc {
    NSAssert(_stoppedObserving, @"stopObserving never called");
}

- (id)initWithBlock:(RGKVOBlock)block object:(id)object keyPath:(NSString *)keyPath {
    if ((self = [super init])) {
        [self setBlock:block];
        [self setObject:object];
        [self setKeyPath:keyPath];
    }
    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {

    if (self.block) {
        self.block(change);
    };
}

- (void)stopObserving {
    if (!_stoppedObserving) {
        id object = self.object;
        if (object) {
            [object removeObserver:self forKeyPath:self.keyPath];
            _stoppedObserving = YES;
        }
    }
}

@end


@interface RGKVOObserver ()

@property (nonatomic, strong, readonly) id object;
@property (nonatomic, strong, readonly) NSString *keypath;

@end

@implementation RGKVOObserver

- (id)initWithObject:(id)object keypath:(NSString*)keypath {
    if (!object || !keypath) {
        return nil;
    }
    if (self = [super init]) {
        _object = object;
        _keypath = keypath;
    }
    return self;
}

- (RGKVOHandle *)observe:(RGSimpleKVOBlock)block {
    if (!block) {
        return nil;
    }
    
    return [self observe:^(NSDictionary *change) {
        block(change[NSKeyValueChangeNewKey]);
        
    } options:NSKeyValueObservingOptionNew];
}

- (RGKVOHandle *)observe:(RGSimpleKVOBlock)block queue:(dispatch_queue_t)queue {
    if (!block) {
        return nil;
    }
    
    return [self observe:^(NSDictionary *change) {
        block(change[NSKeyValueChangeNewKey]);
        
    } options:NSKeyValueObservingOptionNew queue:queue];
    
}

- (RGKVOHandle *)observeOnMain:(RGSimpleKVOBlock)block {
    if (!block) {
        return nil;
    }
    
    return [self observeOnMain:^(NSDictionary *change) {
        block(change[NSKeyValueChangeNewKey]);
        
    } options:NSKeyValueObservingOptionNew];
}

- (RGKVOHandle *)observe:(RGKVOBlock)block options:(NSKeyValueObservingOptions)options {
    if (!block) {
        return nil;
    }
    
    RGKVOHandle *observer = [[RGKVOHandle alloc] initWithBlock:block object:self.object keyPath:self.keypath];
    [self.object addObserver:observer forKeyPath:self.keypath options:options context:NULL];
    return observer;
}

- (RGKVOHandle *)observe:(RGKVOBlock)block options:(NSKeyValueObservingOptions)options queue:(dispatch_queue_t)queue {
    if (!block) {
        return nil;
    }
    
    return [self observe:^(NSDictionary *change) {
        dispatch_async(queue, ^{
            block(change);
        });
        
    } options:options];
}

- (RGKVOHandle *)observeOnMain:(RGKVOBlock)block options:(NSKeyValueObservingOptions)options {
    if (!block) {
        return nil;
    }
    
    return [self observe:^(NSDictionary *change) {
        if ([NSThread isMainThread]) {
            block(change);
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                block(change);
            });
        }
        
    } options:options];
}

@end