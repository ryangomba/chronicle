//  Copyright 2013-present Ryan Gomba. All rights reserved.

@interface UIView (Framing)

- (CGFloat)frameX;
- (CGFloat)frameY;
- (CGFloat)frameWidth;
- (CGFloat)frameHeight;

- (void)setOrigin:(CGPoint)point;
- (void)setX:(CGFloat)x;
- (void)setY:(CGFloat)x;

- (void)setSize:(CGSize)size;
- (void)setWidth:(CGFloat)width;
- (void)setHeight:(CGFloat)height;

@end
