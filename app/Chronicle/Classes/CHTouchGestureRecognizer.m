#import "CHTouchGestureRecognizer.h"
#import <UIKit/UIGestureRecognizerSubclass.h>

@interface CHTouchGestureRecognizer ()

@property (nonatomic, assign, readwrite) BOOL didPress;

@end


@implementation CHTouchGestureRecognizer

@dynamic delegate;

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];

    [self performSelector:@selector(beginIfNotBegunAlready) withObject:nil afterDelay:0.25];
}

- (void)beginIfNotBegunAlready {
    if (self.state == UIGestureRecognizerStatePossible) {
        [self.delegate touchGestureRecognizerDidLongPress:self];
        [self setState:UIGestureRecognizerStateBegan];
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesMoved:touches withEvent:event];

  [touches enumerateObjectsUsingBlock:^(UITouch * _Nonnull touch, BOOL * _Nonnull stop) {
    if (!CGPointEqualToPoint([touch locationInView:nil], [touch previousLocationInView:nil])) {
[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(beginIfNotBegunAlready) object:nil];
      *stop = true;
    }
  }];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesCancelled:touches withEvent:event];
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(beginIfNotBegunAlready) object:nil];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesEnded:touches withEvent:event];
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(beginIfNotBegunAlready) object:nil];
}

@end
