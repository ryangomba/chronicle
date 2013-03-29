#import "CHNavigationController.h"
#import <POP/POP.h>
#import <POP/POPLayerExtras.h>
#import "CHConstants.h"
#import <RGInterfaceKit/RGInterfaceKit.h>
#import "RGTransformableView.h"

#define kMinScale 1.0 // disable

@interface CHNavigationController ()<UIGestureRecognizerDelegate>

@property (nonatomic, readonly) UIViewController *topVC;
@property (nonatomic, readonly) UIViewController *bottomVC;

@property (nonatomic, strong) NSMutableArray *overlayViews;

@property (nonatomic, strong) UIPanGestureRecognizer *panGestureRecognizer;

@end


@implementation CHNavigationController

- (id)initWithRootViewController:(UIViewController *)viewController {
    if (self = [super initWithNibName:nil bundle:nil]) {
        self.overlayViews = [[NSMutableArray alloc] init];
        
        self.panGestureRecognizer = [UIPanGestureRecognizer new];
        [self.panGestureRecognizer addTarget:self action:@selector(onPan:)];
        [self.view addGestureRecognizer:self.panGestureRecognizer];
        self.panGestureRecognizer.delegate = self;
        
        [self pushViewController:viewController animated:NO];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    //
}

- (UIViewController *)topVC {
    return self.childViewControllers.lastObject;
}

- (UIViewController *)bottomVC {
    NSInteger numberOfViewControllers = self.childViewControllers.count;
    return self.childViewControllers[numberOfViewControllers - 2];
}

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    if (self.childViewControllers.count > 0) {
        UIView *overlayView = [[UIView alloc] initWithFrame:self.view.bounds];
        overlayView.backgroundColor = BLACK_COLOR(0.85);
        overlayView.alpha = 0.0;
        [self.view addSubview:overlayView];
        [self.overlayViews addObject:overlayView];
    }
    
    [self addChildViewController:viewController];
    viewController.view.frame = self.view.bounds;
    [self.view addSubview:viewController.view];
    [viewController didMoveToParentViewController:self];
    
    if (animated) {
        CGFloat startingX = self.view.bounds.size.width;
        [self.topVC.view setX:startingX];
        
        [self animateToPosition:0.0 withVelocity:0.0 completion:nil];
    }
}

- (void)popViewControllerAnimated:(BOOL)animated {
    [self popViewControllerAnimated:animated withVelocity:0.0];
}

- (void)popViewControllerAnimated:(BOOL)animated withVelocity:(CGFloat)velocity {
    void (^completionBlock)(void) = ^{
        [self.topVC willMoveToParentViewController:nil];
        [self.topVC.view removeFromSuperview];
        [self.topVC removeFromParentViewController];
        [self.overlayViews.lastObject removeFromSuperview];
        [self.overlayViews removeLastObject];
    };
    
    if (animated) {
        [self animateToPosition:1.0 withVelocity:velocity completion:completionBlock];
        
    } else {
        completionBlock();
    }
}

- (void)cancelPopWithVelocity:(CGFloat)velocity {
    [self animateToPosition:0.0 withVelocity:velocity completion:nil];
}

- (void)animateToPosition:(CGFloat)position
             withVelocity:(CGFloat)velocity
               completion:(void (^)(void))completion {
    
    UIView *overlayView = self.overlayViews.lastObject;
    
    POPSpringAnimation *animation = [POPSpringAnimation animation];
    animation.property = [POPAnimatableProperty propertyWithName:@"skdjfh" initializer:^(POPMutableAnimatableProperty *prop) {
        prop.readBlock = ^(CHNavigationController *controller, CGFloat *values) {
            CGFloat currentX = self.topVC.view.frame.origin.x; // TODO retain cycle
            CGFloat normalizedX = currentX / self.view.bounds.size.width;
            values[0] = normalizedX;
        };
        prop.writeBlock = ^(CHNavigationController *controller, const CGFloat *values) {
            CGFloat normalizedX = values[0];
            CGFloat scale = kMinScale + normalizedX * (1.0 - kMinScale);
            CGFloat x = normalizedX * self.view.bounds.size.width;
            [self.topVC.view setX:x];
            self.bottomVC.view.transform = CGAffineTransformMakeScale(scale, scale);
            overlayView.alpha = 1.0 - normalizedX;
        };
        prop.threshold = 0.01;
    }];
    animation.completionBlock = ^(POPAnimation *anim, BOOL finished) {
        if (completion) {
            completion();
        }
    };
    animation.springBounciness = 0.0;
    animation.springSpeed = 20.0;
    animation.velocity = @(velocity / self.view.bounds.size.width);
    CGFloat currentX = self.topVC.view.frame.origin.x; // TODO retain cycle
    CGFloat normalizedX = currentX / self.view.bounds.size.width;
    animation.fromValue = @(normalizedX);
    animation.toValue = @(position);
    [self pop_addAnimation:animation forKey:@"sjdkfhskd"];
}

#pragma mark -
#pragma mark UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer == self.panGestureRecognizer) {
        if ([RGTransformableView isActive]) {
            return NO;
        }
        CGPoint translation = [self.panGestureRecognizer translationInView:self.view];
        return ABS(translation.x) > ABS(translation.y) && translation.x > 0;
    }
    return YES;
}


#pragma mark -
#pragma mark Action Listeners

- (void)onPan:(UIPanGestureRecognizer *)recognizer {
    static CGFloat startPanX;
    
    NSInteger numberOfViewControllers = self.childViewControllers.count;
    if (numberOfViewControllers == 1) {
        return;
    }
    
    switch (recognizer.state) {
        case UIGestureRecognizerStateBegan:
            startPanX = [recognizer locationInView:self.view].x;
            break;
            
        case UIGestureRecognizerStateChanged: {
            CGFloat x = [recognizer locationInView:self.view].x - startPanX;
            [self.topVC.view setX:x];
            
            CGFloat amountPushed = x / self.view.bounds.size.width;
            CGFloat scale = 1.0 - (1.0 - kMinScale) * (1.0 - amountPushed);
            self.bottomVC.view.transform = CGAffineTransformMakeScale(scale, scale);
            
            UIView *overlayView = self.overlayViews.lastObject;
            overlayView.alpha = 1.0 - amountPushed;
        } break;
            
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled: {
            CGFloat velocityX = [recognizer velocityInView:self.view].x;
            if (velocityX > 0) {
                [self popViewControllerAnimated:YES withVelocity:velocityX];
            } else {
                [self cancelPopWithVelocity:velocityX];
            }
        } break;
            
        case UIGestureRecognizerStateFailed:
        case UIGestureRecognizerStatePossible:
            break;
    }
}

@end
