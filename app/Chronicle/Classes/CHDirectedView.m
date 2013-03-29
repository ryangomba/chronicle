#import "CHDirectedView.h"
#import <RGInterfaceKit/RGInterfaceKit.h>
#import "UIView+Animations.h"

@interface CHDirectedView ()

@property (nonatomic, strong) UIImageView *caretView;

@end


@implementation CHDirectedView

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setBackgroundColor:[UIColor whiteColor]];
        
        [self setCaretPosition:0.5];
        [self addSubview:self.caretView];
    }
    return self;
}

- (UIImageView *)caretView {
    if (!_caretView) {
        UIImage *caretImage = [UIImage imageNamed:@"caret.png"];
        _caretView = [[UIImageView alloc] initWithImage:caretImage];
    }
    return _caretView;
}

- (void)setCaretPosition:(CGFloat)caretPosition {
    _caretPosition = caretPosition;
    
    [self setAnchorPoint:CGPointMake(caretPosition, 0.0)];
    [self setNeedsLayout];
}

- (void)layoutSubviews {
    [super layoutSubviews];

    NSInteger caretX = self.frameWidth * self.caretPosition;
    NSInteger caretY = -self.caretView.frameHeight / 2;
    [self.caretView setCenter:CGPointMake(caretX, caretY)];
}

@end
