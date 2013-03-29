//  Copyright 2013-present Ryan Gomba. All rights reserved.

@interface NSObject (Blocks)

- (void)performAfterDelay:(NSTimeInterval)delay blockOperation:(void (^)(void))block;
- (void)performInNextRunLoop:(void (^)(void))block;

@end
