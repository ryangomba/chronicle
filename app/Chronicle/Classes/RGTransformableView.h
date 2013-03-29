#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class RGTransformableView;
@protocol RGTransformableViewDelegate<NSObject>

@optional
- (BOOL)transformableViewShouldScale:(RGTransformableView *)view;
- (BOOL)transformableViewShouldTranslateX:(RGTransformableView *)view;
- (BOOL)transformableViewShouldTranslateY:(RGTransformableView *)view;

- (void)transformableViewWillBeginUserInteraction:(RGTransformableView *)view;
- (void)transformableViewWillFinishUserInteraction:(RGTransformableView *)view;

- (BOOL)transformableViewShouldReceieveTap:(RGTransformableView *)view;
- (void)transformableViewDidReceieveTap:(RGTransformableView *)view;

- (void)transformableViewDidReceieveLongPress:(RGTransformableView *)view;

- (void)transformableViewDidTransform:(RGTransformableView *)view;

@end


@interface RGTransformableView : UIView

// TODO SUCH HACKS
@property (nonatomic, readonly) id attachedModel;
@property (nonatomic, strong, readonly) UITapGestureRecognizer *tapRecognizer;

@property (nonatomic, strong, readonly) UIView *contentView;
@property (nonatomic, assign) CGFloat aspectRatio;

@property (nonatomic, assign) CGSize desiredSize;

@property (nonatomic, weak, readonly) UIView *targetView;
@property (nonatomic, assign, readonly) CGPoint desiredCenter;

@property (nonatomic, assign) CGPoint velocity;

@property (nonatomic, assign, readonly) CGFloat scale;
@property (nonatomic, assign) CGFloat scaleVelocity;

@property (nonatomic, assign, readonly) BOOL isUserScaling;
@property (nonatomic, assign, readonly) BOOL isScaling;
@property (nonatomic, assign, readonly) BOOL isUserTranslating;
@property (nonatomic, assign, readonly) BOOL isTranslating;

@property (nonatomic, weak) id<RGTransformableViewDelegate> delegate;

+ (BOOL)isActive;

- (void)setDesiredCenter:(CGPoint)desiredCenter inTargetView:(UIView *)targetView;
- (void)moveToDesiredPositionAnimated:(BOOL)animated;
- (void)removeFromViewHierarchy;

- (void)setShadowed:(BOOL)shadowed animated:(BOOL)animated;

// HACK overrrides
- (void)notifyDelegateWillBeginUserInteraction;
- (void)notifyDelegateWillFinishUserInteraction;

@end
