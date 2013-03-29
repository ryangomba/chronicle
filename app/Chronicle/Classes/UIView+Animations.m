#import "UIView+Animations.h"

#import <QuartzCore/QuartzCore.h>

@implementation UIView (Animations)

- (void)setAnchorPoint:(CGPoint)anchorPoint {
    CGPoint newPoint = CGPointMake(self.bounds.size.width * anchorPoint.x, self.bounds.size.height * anchorPoint.y);
    CGPoint oldPoint = CGPointMake(self.bounds.size.width * self.layer.anchorPoint.x, self.bounds.size.height * self.layer.anchorPoint.y);

    newPoint = CGPointApplyAffineTransform(newPoint, self.transform);
    oldPoint = CGPointApplyAffineTransform(oldPoint, self.transform);

    CGPoint position = self.layer.position;

    position.x -= oldPoint.x;
    position.x += newPoint.x;

    position.y -= oldPoint.y;
    position.y += newPoint.y;

    [CATransaction setDisableActions:YES];
    [self.layer setPosition:position];
    [self.layer setAnchorPoint:anchorPoint];
    [CATransaction setDisableActions:NO];
}

@end
