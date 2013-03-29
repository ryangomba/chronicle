// Copyright 2014-present Ryan Gomba. All Rights Reserved.

#import "NSSet+Additions.h"

@implementation NSSet (Additions)

- (NSSet *)setBySubtractingSet:(NSSet *)set {
    NSMutableSet *mutableCopy = [self mutableCopy];
    [mutableCopy minusSet:set];
    return [mutableCopy copy];
}

@end
