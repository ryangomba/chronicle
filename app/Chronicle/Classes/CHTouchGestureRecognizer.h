#import <UIKit/UIKit.h>

@class CHTouchGestureRecognizer;
@protocol CHTouchGestureRecognizerDelegate <UIGestureRecognizerDelegate>

- (void)touchGestureRecognizerDidLongPress:(CHTouchGestureRecognizer *)recogizer;

@end

@interface CHTouchGestureRecognizer : UIPanGestureRecognizer

@property (nonatomic, assign) id<CHTouchGestureRecognizerDelegate> delegate;

@end
