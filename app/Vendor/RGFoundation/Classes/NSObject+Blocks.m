//  Copyright 2013-present Ryan Gomba. All rights reserved.

#import "NSObject+Blocks.h"

@implementation NSObject (Blocks)

- (void)performAfterDelay:(NSTimeInterval)delay blockOperation:(void (^)(void))block {
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delay * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), block);
}

- (void)performInNextRunLoop:(void (^)(void))block {
    [self performAfterDelay:0.01 blockOperation:block];
}

@end

