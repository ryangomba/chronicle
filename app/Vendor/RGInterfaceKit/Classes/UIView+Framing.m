//  Copyright 2013-present Ryan Gomba. All rights reserved.

#import "UIView+Framing.h"

@implementation UIView (Framing)

- (CGFloat)frameX {
    return self.frame.origin.x;
}

- (CGFloat)frameY {
    return self.frame.origin.y;
}

- (CGFloat)frameHeight {
    return self.frame.size.height;
}

- (CGFloat)frameWidth {
    return self.frame.size.width;
}

- (void)setOrigin:(CGPoint)point {
    CGRect frame = self.frame;
    frame.origin = point;
    [self setFrame:frame];
}

- (void)setX:(CGFloat)x {
    CGRect frame = self.frame;
    frame.origin.x = x;
    [self setFrame:frame];
}

- (void)setY:(CGFloat)y {
    CGRect frame = self.frame;
    frame.origin.y = y;
    [self setFrame:frame];
}

- (void)setSize:(CGSize)size {
    CGRect frame = self.frame;
    frame.size = size;
    [self setFrame:frame];
}

- (void)setWidth:(CGFloat)width {
    CGRect frame = self.frame;
    frame.size.width = width;
    [self setFrame:frame];
}

- (void)setHeight:(CGFloat)height {
    CGRect frame = self.frame;
    frame.size.height = height;
    [self setFrame:frame];
}

@end
