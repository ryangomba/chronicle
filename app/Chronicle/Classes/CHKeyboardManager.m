#import "CHKeyboardManager.h"

typedef NS_ENUM(NSInteger, KeyboardState) {
    KeyboardStateDown,
    KeyboardStateUp,
    KeyboardStateAnimating,
};

@interface CHKeyboardManager ()

@property (nonatomic, assign, readwrite) KeyboardState keyboardState;
@property (nonatomic, assign, readwrite) CGFloat animationDuration;
@property (nonatomic, assign, readwrite) UIViewAnimationCurve animationCurve;

@end


@implementation CHKeyboardManager

#pragma mark -
#pragma mark NSObject

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)init {
    if (self = [super init]) {
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc addObserver:self selector:@selector(onKeyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
        [nc addObserver:self selector:@selector(onKeyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
        [nc addObserver:self selector:@selector(onKeyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
        [nc addObserver:self selector:@selector(onKeyboardDidHide:) name:UIKeyboardDidHideNotification object:nil];
        [nc addObserver:self selector:@selector(onKeyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
    }
    return self;
}


#pragma mark -
#pragma mark Notification Listeners

- (void)onKeyboardWillShow:(NSNotification *)notification {
    if (self.keyboardState != KeyboardStateUp) {
        self.keyboardState = KeyboardStateAnimating;
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
    }
    [self updateKeyboardWithNotification:notification];
}

- (void)onKeyboardDidShow:(NSNotification *)notification {
    self.keyboardState = KeyboardStateUp;
}

- (void)onKeyboardWillHide:(NSNotification *)notification {
    self.keyboardState = KeyboardStateAnimating;
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self updateKeyboardWithNotification:notification];
}

- (void)onKeyboardDidHide:(NSNotification *)notification {
    self.keyboardState = KeyboardStateDown;
}

- (void)onKeyboardWillChangeFrame:(NSNotification *)notification {
    [self updateKeyboardWithNotification:notification];
    
    [self performSelector:@selector(notifyDelegateOfFrameChange)
               withObject:nil
               afterDelay:0.0];
}


#pragma mark -
#pragma mark Delegate

- (void)notifyDelegateOfFrameChange {
    [self.delegate keyboardManagerKeyboardDidChangeFrame:self];
}


#pragma mark -
#pragma mark Private

- (void)updateKeyboardWithNotification:(NSNotification *)notification {
    self.animationDuration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] floatValue];
    self.animationCurve = [notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue];
    
    CGRect endFrame = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    UIView *superview = self.scrollView.superview;
    CGFloat keyboardY = CGRectGetMinY([superview convertRect:endFrame fromView:nil]);
    CGFloat keyboardDistanceFromBottom = superview.bounds.size.height - keyboardY;
    
    UIEdgeInsets insets = UIEdgeInsetsMake(0.0, 0.0, keyboardDistanceFromBottom, 0.0);
    self.scrollView.contentInset = insets;
    self.scrollView.scrollIndicatorInsets = insets;
}

@end
