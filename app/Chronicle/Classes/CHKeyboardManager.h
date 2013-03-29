#import <UIKit/UIKit.h>

@class CHKeyboardManager;
@protocol CHKeyboardManagerDelegate <NSObject>

- (void)keyboardManagerKeyboardDidChangeFrame:(CHKeyboardManager *)keyboardManager;

@end

@interface CHKeyboardManager : NSObject

@property (nonatomic, strong) UIScrollView *scrollView;

@property (nonatomic, assign, readonly) BOOL keyboardIsAnimating;
@property (nonatomic, assign, readonly) CGFloat animationDuration;
@property (nonatomic, assign, readonly) UIViewAnimationCurve animationCurve;

@property (nonatomic, weak) id<CHKeyboardManagerDelegate> delegate;

@end
