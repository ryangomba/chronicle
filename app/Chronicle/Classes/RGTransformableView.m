#import "RGTransformableView.h"

#import <pop/POP.h>
#import <pop/POPLayerExtras.h>
#import <RGCore/RGCore.h>
#import "RGGeometry.h"
#import "CHTouchGestureRecognizer.h"

static NSString * const kScaleKey = @"scaleKey";
static NSString * const kScalePropertyName = @"scaleProp";

static NSString * const kTranslationKey = @"translationKey";
static NSString * const kTranslationPropertyName = @"translationProp";

static NSInteger transformCount = 0;

#define kMultipler 1

@interface RGTransformableView ()<CHTouchGestureRecognizerDelegate> {
    CGPoint _panStart;
    
    CGPoint _touchStartNormalizedPosition;
    CGSize _touchStartSize;
    
//    BOOL _canPanX;
//    BOOL _canPanY;
    
    CGFloat _scaleStart;
    
    CGRect _maskRect;
}

@property (nonatomic, strong, readwrite) UIView *contentView;

@property (nonatomic, weak, readwrite) UIView *targetView;
@property (nonatomic, assign, readwrite) CGPoint desiredCenter;

@property (nonatomic, assign, readwrite) CGFloat scale;

@property (nonatomic, strong) POPSpringAnimation *scaleSpring;
@property (nonatomic, strong) POPSpringAnimation *translationSpring;

@property (nonatomic, strong, readwrite) UITapGestureRecognizer *tapRecognizer;
@property (nonatomic, strong) CHTouchGestureRecognizer *panRecognizer;
@property (nonatomic, strong) UIPinchGestureRecognizer *pinchRecognizer;

@property (nonatomic, assign) BOOL isTransforming;

@property (nonatomic, assign) BOOL shadowed;
@property (nonatomic, strong) UIImageView *shadowView;
#define kShadowOutsetPercent (60.0 / 720.0)

@end

@implementation RGTransformableView

+ (BOOL)isActive {
    return transformCount > 0;
}

- (void)dealloc {
    [self cancelSprings];
}

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        _scale = 1.0;
        _desiredSize = self.bounds.size;

        [self addSubview:self.contentView];
        
        [self addGestureRecognizer:self.tapRecognizer];
        [self addGestureRecognizer:self.pinchRecognizer];
        [self addGestureRecognizer:self.panRecognizer];
        
        [self setShadowed:NO animated:NO];
    }
    return self;
}

#pragma mark -
#pragma mark Properties

- (UIView *)contentView {
    if (!_contentView) {
        _contentView = [[UIView alloc] initWithFrame:self.bounds];
    }
    return _contentView;
}

- (CGFloat)targetScale {
    CGFloat widthScale = self.desiredSize.width / self.bounds.size.width;
    CGFloat heightScale = self.desiredSize.height / self.bounds.size.height;
    return MIN(widthScale, heightScale);
}

- (CGFloat)targetScaleInTargetView {
    CGSize sizeInCurrentView = [self.targetView convertRect:CGRectMake(0.0, 0.0, self.desiredSize.width, self.desiredSize.height) toView:self.window].size;
    CGFloat widthScale = sizeInCurrentView.width / self.bounds.size.width;
    CGFloat heightScale = sizeInCurrentView.height / self.bounds.size.height;
    return MIN(widthScale, heightScale);
}

- (void)mask:(BOOL)animated {
    if (!self.aspectRatio) {
        return;
    }
    
    CGFloat contentRatio = self.aspectRatio;
    CGFloat thumbRatio = self.desiredSize.width / self.desiredSize.height;

    CGPoint newInsetXY = CGPointZero;
    newInsetXY.x = MAX((contentRatio - thumbRatio) * self.bounds.size.height / 2.0, 0.0);
    newInsetXY.y = MAX((thumbRatio - contentRatio) * self.bounds.size.height / 2.0, 0.0);
    
    CGPoint currentOffsetXY = _maskRect.origin;
    if (CGPointEqualToPoint(currentOffsetXY, newInsetXY)) {
        return;
    }
    
    CAShapeLayer *mask = (id)self.contentView.layer.mask;
    
    if (!mask) {
        mask = [[CAShapeLayer alloc] init];
        [self.contentView.layer setMask:mask];
    }
    
    if (!animated) {
        [self pop_removeAnimationForKey:@"mask"];
        _maskRect = CGRectInset(self.contentView.bounds, newInsetXY.x, newInsetXY.y);
        CGPathRef path = [UIBezierPath bezierPathWithRect:_maskRect].CGPath;
        [mask setPath:path];
        return;
    }
    
    POPBasicAnimation *animation = [self pop_animationForKey:@"mask"];
    if (!animation) {
        animation = [POPBasicAnimation animation];
        animation.property = [POPAnimatableProperty propertyWithName:@"mask" initializer:^(POPMutableAnimatableProperty *prop) {
            prop.readBlock = ^(RGTransformableView *view, CGFloat *values) {
                values[0] = view->_maskRect.origin.x; // TODO retain cycle
                values[1] = view->_maskRect.origin.y;
            };
            prop.writeBlock = ^(RGTransformableView *view, const CGFloat *values) {
                view->_maskRect = CGRectInset(view.contentView.bounds, values[0], values[1]);
                CGPathRef path = [UIBezierPath bezierPathWithRect:view->_maskRect].CGPath;
                [mask setPath:path];
            };
        }];
        animation.duration = 0.25;
        [self pop_addAnimation:animation forKey:@"mask"];
    }
    
    animation.fromValue = [NSValue valueWithCGPoint:currentOffsetXY];
    animation.toValue = [NSValue valueWithCGPoint:newInsetXY];
}


#pragma mark -
#pragma mark Shadow

- (UIImageView *)shadowView {
    if (!_shadowView) {
        _shadowView = [[UIImageView alloc] initWithFrame:CGRectZero];
        UIImage *shadowImage = [UIImage imageNamed:@"photo-shadow@2x.png"];
        _shadowView.image = shadowImage;
    }
    return _shadowView;
}

- (void)setBounds:(CGRect)bounds {
    [super setBounds:bounds];
    [self updateShadowPath];
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    [self updateShadowPath];
}

- (void)updateShadowPath {
    CGFloat shadowXInset = -floorf(self.bounds.size.width * kShadowOutsetPercent) + 2;
    CGFloat shadowYInset = -floorf(self.bounds.size.height * kShadowOutsetPercent) + 2;
    self.shadowView.frame = CGRectInset(self.bounds, shadowXInset, shadowYInset);
}

- (void)setShadowed:(BOOL)shadowed animated:(BOOL)animated {
    self.shadowed = shadowed;
    
    [self updateShadowPath];
    [self insertSubview:self.shadowView atIndex:0];
    self.shadowView.alpha = shadowed ? 0.0 : 1.0;
    
    [UIView animateWithDuration:0.25 * animated
                          delay:0.0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         self.shadowView.alpha = shadowed ? 1.0 : 0.0;
                     } completion:^(BOOL finished) {
                         if (!shadowed && finished) {
                             [self.shadowView removeFromSuperview];
                         }
                     }];
}

- (void)setDesiredSize:(CGSize)desiredSize {
    _desiredSize = desiredSize;
    
    BOOL shouldMask = NO;
    CGFloat targetScale;
    CGFloat widthScale = self.desiredSize.width / self.bounds.size.width;
    CGFloat heightScale = self.desiredSize.height / self.bounds.size.height;
    if (desiredSize.width == desiredSize.height) { // HACK for thumbnail
        targetScale = MAX(widthScale, heightScale);
        shouldMask = [self superview] != nil; // avoid masking on initialization
    } else {
        targetScale = MIN(widthScale, heightScale);
    }
    
    CGFloat relativeScale = self.scale / targetScale;
    
    [self setBounds:(CGRect){{0, 0}, desiredSize}];
    
    if (self.aspectRatio) {
        CGFloat contentRatio = self.aspectRatio;
        CGFloat thumbRatio = self.desiredSize.width / self.desiredSize.height;
        CGPoint newInsetXY = CGPointZero;
        newInsetXY.x = MIN(-(contentRatio - thumbRatio) * self.bounds.size.height / 2.0, 0.0);
        newInsetXY.y = MIN(-(thumbRatio - contentRatio) * self.bounds.size.height / 2.0, 0.0);
        [self.contentView setFrame:CGRectInset(self.bounds, newInsetXY.x, newInsetXY.y)];
    } else {
        [self.contentView setFrame:self.bounds];
    }
    
    [self setScale:relativeScale];
    [self updateTransform];

    // TODO seems to be a "bug" in POP; updating from value after a spring has started doesn't change anything
    if ([self pop_animationForKey:kScaleKey]) {
        [self pop_removeAnimationForKey:kScaleKey];
        self.scaleSpring.fromValue = @(relativeScale);
        self.scaleSpring.toValue = @(targetScale);
        [self pop_addAnimation:self.scaleSpring forKey:kScaleKey];
    }
}

- (void)setDesiredCenter:(CGPoint)desiredCenter inTargetView:(UIView *)targetView {
    [self setDesiredCenter:desiredCenter];
    [self setTargetView:targetView];

    self.translationSpring.toValue = [NSValue valueWithCGPoint:desiredCenter];
}

- (void)moveToDesiredPositionAnimated:(BOOL)animated {
    if (_isTransforming) {
        [self doFinishTransformAnimated:YES];
        
    } else if (!animated) {
        [self moveToTargetView];
        
    } else {
        [self moveToWindow];
        [self doFinishTransformAnimated:YES];
    }
}

- (void)moveToTargetView {
    [self cancelSprings];
    
    [self.targetView addSubview:self];
    [self moveToCenter:self.desiredCenter];

    [self setScale:[self targetScale]];
    [self updateTransform];
}

- (CGPoint)windowPointForCurrentCenter {
    RGAssert(self.window);
    return [self.superview convertPoint:self.center toView:nil];
}

- (CGPoint)windowPointForDesiredCenterInTargetView {
    RGAssert(self.targetView.window);
    return [self.targetView convertPoint:self.desiredCenter toView:nil];
}

- (void)moveToWindow {
    CGPoint newCenter = [self windowPointForCurrentCenter];
    RGAssert(self.window);
    [self.window addSubview:self];
    [self moveToCenter:newCenter];
}

- (void)moveToCenter:(CGPoint)center {
    [self setCenter:center];
}

- (void)setScale:(CGFloat)scale {
    _scale = MAX(scale, 0.05);
}

- (BOOL)isTrackingScale {
    return (self.pinchRecognizer.state == UIGestureRecognizerStateBegan ||
            self.pinchRecognizer.state == UIGestureRecognizerStateChanged);
}

- (BOOL)isUserScaling {
    return (self.pinchRecognizer.state == UIGestureRecognizerStateBegan ||
            self.pinchRecognizer.state == UIGestureRecognizerStateChanged ||
            self.pinchRecognizer.state == UIGestureRecognizerStateEnded);
}

- (BOOL)isScaling {
    CGFloat scaleVelocity = [self.scaleSpring.velocity floatValue];
    return (self.isUserScaling || ABS(scaleVelocity) > 0.01);
}

- (BOOL)isTrackingTranslation {
    return (self.panRecognizer.state == UIGestureRecognizerStateBegan ||
            self.panRecognizer.state == UIGestureRecognizerStateChanged);
}

- (BOOL)isUserTranslating {
    return (self.panRecognizer.state == UIGestureRecognizerStateBegan ||
            self.panRecognizer.state == UIGestureRecognizerStateChanged ||
            self.panRecognizer.state == UIGestureRecognizerStateEnded);
}

- (BOOL)isTranslating {
    CGPoint translationVelocity = [self.translationSpring.velocity CGPointValue];
    return (self.isUserTranslating || !CGPointEqualToPoint(translationVelocity, CGPointZero));
}

- (void)removeFromViewHierarchy {
    [self removeFromSuperview];
    [self setTargetView:nil];
    [self cancelSprings];
}


#pragma mark - Delegate Calls

- (BOOL)shouldScale {
    if ([self.delegate respondsToSelector:@selector(transformableViewShouldScale:)]) {
        return [self.delegate transformableViewShouldScale:self];
    }
    return NO;
}

- (BOOL)shouldTranslateX {
    if ([self.delegate respondsToSelector:@selector(transformableViewShouldTranslateX:)]) {
        return [self.delegate transformableViewShouldTranslateX:self];
    }
    return NO;
}

- (BOOL)shouldTranslateY {
    if ([self.delegate respondsToSelector:@selector(transformableViewShouldTranslateY:)]) {
        return [self.delegate transformableViewShouldTranslateY:self];
    }
    return NO;
}

- (BOOL)shouldReceieveTap {
    if ([self.delegate respondsToSelector:@selector(transformableViewShouldReceieveTap:)]) {
        return [self.delegate transformableViewShouldReceieveTap:self];
    }
    return NO;
}

- (void)notifyDelegateWillBeginUserInteraction {
    transformCount++;
    if ([self.delegate respondsToSelector:@selector(transformableViewWillBeginUserInteraction:)]) {
        [self.delegate transformableViewWillBeginUserInteraction:self];
    }
}

- (void)notifyDelegateWillFinishUserInteraction {
    transformCount--;
    if ([self.delegate respondsToSelector:@selector(transformableViewWillFinishUserInteraction:)]) {
        [self.delegate transformableViewWillFinishUserInteraction:self];
    }
}

- (void)notifyDelegateDidReceieveTap {
    if ([self.delegate respondsToSelector:@selector(transformableViewDidReceieveTap:)]) {
        [self.delegate transformableViewDidReceieveTap:self];
    }
}

- (void)notifyDelegateDidTransform {
    if ([self.delegate respondsToSelector:@selector(transformableViewDidTransform:)]) {
        [self.delegate transformableViewDidTransform:self];
    }
}


#pragma mark -
#pragma mark Gesture Recognizers

- (UITapGestureRecognizer *)tapRecognizer {
    if (!_tapRecognizer) {
        _tapRecognizer = [[UITapGestureRecognizer alloc] init];
        [_tapRecognizer addTarget:self action:@selector(onTap:)];
        [_tapRecognizer setDelegate:self];
    }
    return _tapRecognizer;
}

- (CHTouchGestureRecognizer *)panRecognizer {
    if (!_panRecognizer) {
        _panRecognizer = [[CHTouchGestureRecognizer alloc] init];
        [_panRecognizer addTarget:self action:@selector(onPan:)];
        [_panRecognizer setDelegate:self];
    }
    return _panRecognizer;
}

- (UIPinchGestureRecognizer *)pinchRecognizer {
    if (!_pinchRecognizer) {
        _pinchRecognizer = [[UIPinchGestureRecognizer alloc] init];
        [_pinchRecognizer addTarget:self action:@selector(onPinch:)];
        [_pinchRecognizer setDelegate:self];
    }
    return _pinchRecognizer;
}


#pragma mark -
#pragma mark UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
       shouldReceiveTouch:(UITouch *)touch {
    
    if (gestureRecognizer == self.pinchRecognizer) {
        return [self shouldScale];
    }
    
    if (gestureRecognizer == self.panRecognizer) {
        return YES;// [self shouldTranslateX] || [self shouldTranslateY];
    }
    
    if (gestureRecognizer == self.tapRecognizer) {
        return [self shouldReceieveTap];
    }
    
    return YES;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer == self.tapRecognizer) {
        return !self.isUserTranslating && !self.isUserScaling;
    }
    if (gestureRecognizer == self.panRecognizer) {
        return [self shouldTranslateX] || [self shouldTranslateY];
    }
    
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    if (gestureRecognizer == self.tapRecognizer) {
        return NO;
    }
    return YES;
}



#pragma mark -
#pragma mark Gesture Recoginzer Events

- (void)onTap:(UITapGestureRecognizer *)recognizer {
    [self notifyDelegateDidReceieveTap];
}

- (void)onPan:(UIPanGestureRecognizer *)recognizer {
    switch (recognizer.state) {
        case UIGestureRecognizerStateBegan: {
            _panStart = [self windowPointForCurrentCenter];
            
            [self pop_removeAnimationForKey:kTranslationKey];
            [self beginTransform];
            
        } break;
            
        case UIGestureRecognizerStateChanged: {
            [self updateTransform]; // TODO really?
            [self notifyDelegateDidTransform];
        } break;
            
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled: {
            [self finishTransform];
            
            [self setVelocity:CGPointZero];
        } break;
            
        default:
            break;
    }
}

- (void)onPinch:(UIPinchGestureRecognizer *)recognizer {
    switch (recognizer.state) {
        case UIGestureRecognizerStateBegan:
            _scaleStart = self.scale;
            
            [self pop_removeAnimationForKey:kScaleKey];
            [self setScaleVelocity:recognizer.velocity];
            [self beginTransform];
            break;
            
        case UIGestureRecognizerStateChanged:
            [self setScaleVelocity:recognizer.velocity];
            
            [self setScale:_scaleStart * recognizer.scale];
            [self updateTransform];
            [self notifyDelegateDidTransform];
            break;
            
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled: {
            [self finishTransform];
            [self setScaleVelocity:0.0];
        } break;
            
        default:
            break;
    }
}

- (void)touchGestureRecognizerDidLongPress:(CHTouchGestureRecognizer *)recognizer {
    _panStart = [self windowPointForCurrentCenter]; // HACK
    
    CGPoint touchPoint = [recognizer locationInView:self];
    CGFloat touchNormalX = touchPoint.x / self.bounds.size.width;
    CGFloat touchNormalY = touchPoint.y / self.bounds.size.height;
    _touchStartNormalizedPosition = CGPointMake(touchNormalX, touchNormalY);
    _touchStartSize = CGSizeMultiply(self.bounds.size, self.scale);
    
    if ([self.delegate respondsToSelector:@selector(transformableViewDidReceieveLongPress:)]) {
        [self.delegate transformableViewDidReceieveLongPress:self];
    }
}


#pragma mark -
#pragma mark Transformation

- (void)beginTransform {
    // TOOD this _isTransforming is weird
    if (!_isTransforming) {
        _isTransforming = YES;
        
        [self setShadowed:YES animated:YES];
        [self notifyDelegateWillBeginUserInteraction];
        [self moveToWindow];
    }
}

- (CGPoint)touchTranslation {
    CGFloat translateX = 0.0;
    CGFloat translateY = 0.0;
    if (self.isTransforming) {
        CGPoint touchLocation = _touchStartNormalizedPosition;
        CGSize currentSize = CGSizeMultiply(self.bounds.size, self.scale);
        
        CGFloat startX = touchLocation.x * _touchStartSize.width;
        CGFloat startY = touchLocation.y * _touchStartSize.height;
        CGFloat currentX = touchLocation.x * currentSize.width;
        CGFloat currentY = touchLocation.y * currentSize.height;
        CGFloat xSideDelta = (_touchStartSize.width - currentSize.width) / 2.0;
        CGFloat ySideDelta = (_touchStartSize.height - currentSize.height) / 2.0;
        translateX = startX - (xSideDelta + currentX);
        translateY = startY - (ySideDelta + currentY);
    }
    return CGPointMake(translateX, translateY);
}

- (void)updateTransform {
    [self setNeedsLayout];
}

- (void)layoutSubviews {
    [super layoutSubviews];

    CGFloat scale = self.scale;
    
    CGAffineTransform transform = CGAffineTransformIdentity;
    transform = CGAffineTransformScale(transform, scale, scale);
    [self setTransform:transform];
    
    if ([self isTrackingTranslation]) {
        NSAssert(!CGPointEqualToPoint(_panStart, CGPointZero), @"Too soon");
        
        BOOL shouldTranslateX = [self shouldTranslateX];
        BOOL shouldTranslateY = [self shouldTranslateY];
        
        CGPoint velocity = [self.panRecognizer velocityInView:nil];
        velocity.x *= shouldTranslateX;
        velocity.y *= shouldTranslateY;
        [self setVelocity:velocity];
        
        UIView *staticView = [UIApplication sharedApplication].keyWindow;
        CGPoint deltaTranslation = [self.panRecognizer translationInView:staticView];
        CGPoint newTranslation = CGPointZero;
        newTranslation.x = _panStart.x + deltaTranslation.x;
        newTranslation.y = _panStart.y + deltaTranslation.y;
        if (!shouldTranslateX) {
            newTranslation.x = self.center.x;
        }
        if (!shouldTranslateY) {
            newTranslation.y = self.center.y;
        }
        newTranslation = CGPointOffset(newTranslation, [self touchTranslation]);
        [self moveToCenter:newTranslation];
    }
}

- (void)finishTransform {
    if ([self isTrackingScale] || [self isTrackingTranslation]) {
        return;
    }
    
    _isTransforming = NO;
    
    [self notifyDelegateWillFinishUserInteraction];
    
    if (self.superview != self.window) {
        [self moveToWindow];
    }
    [self setShadowed:NO animated:YES];
    [self doFinishTransformAnimated:YES];
}

- (void)cancelSprings {
    [self pop_removeAnimationForKey:kScaleKey];
    [self pop_removeAnimationForKey:kTranslationKey];
}

- (void)doFinishTransformAnimated:(BOOL)animated {
    [self doFinishScaling];
    [self doFinishTranslating];
    [self mask:animated];
}

- (POPSpringAnimation *)scaleSpring {
    if (!_scaleSpring) {
        _scaleSpring = [POPSpringAnimation animation];
        _scaleSpring.dynamicsTension = 300.0;
        _scaleSpring.dynamicsFriction = 30.0;
        _scaleSpring.dynamicsMass = 1.0;
        _scaleSpring.property =
        [POPAnimatableProperty propertyWithName:kScalePropertyName initializer:^(POPMutableAnimatableProperty *prop) {
            prop.readBlock = ^(RGTransformableView *view, CGFloat *values) {
                values[0] = view.scale;
            };
            prop.writeBlock = ^(RGTransformableView *view, const CGFloat *values) {
                CGFloat intendedScale = values[0];
                view.scale = intendedScale;
                [view updateTransform];
                [view notifyDelegateDidTransform];
            };
            prop.threshold = 0.01;
        }];
    }
    return _scaleSpring;
}

- (void)doFinishScaling {
    if (![self isTrackingScale]) {
        [self pop_addAnimation:self.scaleSpring forKey:kScaleKey];
        self.scaleSpring.velocity = @(self.scaleVelocity);
        self.scaleSpring.fromValue = @(self.scale);
        self.scaleSpring.toValue = @([self targetScaleInTargetView]);
    }
}

- (POPSpringAnimation *)translationSpring {
    if (!_translationSpring) {
        _translationSpring = [POPSpringAnimation animation];
        _translationSpring.dynamicsTension = 300.0;
        _translationSpring.dynamicsFriction = 30.0;
        _translationSpring.dynamicsMass = 1.0;
        _translationSpring.property =
        [POPAnimatableProperty propertyWithName:kTranslationPropertyName initializer:^(POPMutableAnimatableProperty *prop) {
            prop.readBlock = ^(RGTransformableView *view, CGFloat *values) {
                values[0] = view.center.x;
                values[0] = view.center.y;
            };
            prop.writeBlock = ^(RGTransformableView *view, const CGFloat *values) {
                CGFloat deltaX = 0.0;
                CGFloat deltaY = 0.0;
                if (view.targetView.window) {
                    CGPoint originalTarget = [view.translationSpring.toValue CGPointValue];
                    CGPoint newTarget = [view windowPointForDesiredCenterInTargetView];
                    deltaX = newTarget.x - originalTarget.x;
                    deltaY = newTarget.y - originalTarget.y;
                }
                [view moveToCenter:CGPointMake(values[0] + deltaX, values[1] + deltaY)];
                [view setVelocity:[view.translationSpring.velocity CGPointValue]];
                [view notifyDelegateDidTransform];
            };
            prop.threshold = 0.01;
        }];
        weakify(self);
        _translationSpring.completionBlock = ^(POPAnimation *animation, BOOL finished) {
            if (finished) {
                // TODO this is not the real completion block
                // Should also wait for scale
                strongify(self);
                if (!self.isTransforming) {
                    NSAssert(self.targetView != nil, @"Target view is nil");
                    if (self.targetView) {
                        [self moveToTargetView];
                    } else {
                        [self removeFromViewHierarchy];
                    }
                }
            }
        };
    }
    return _translationSpring;
}

- (void)doFinishTranslating {
    if (![self isTrackingTranslation]) {
        [self pop_addAnimation:self.translationSpring forKey:kTranslationKey];
        
        self.translationSpring.velocity = [NSValue valueWithCGPoint:self.velocity];
        self.translationSpring.fromValue = [NSValue valueWithCGPoint:[self windowPointForCurrentCenter]];
        self.translationSpring.toValue = [NSValue valueWithCGPoint:[self windowPointForDesiredCenterInTargetView]];
    }
}

@end
