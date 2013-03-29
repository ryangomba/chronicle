#import "CHHeaderView.h"
#import "CHConstants.h"
#import <RGInterfaceKit/RGInterfaceKit.h>

@interface CHHeaderView ()

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIView *leftBarView;
@property (nonatomic, strong) UIView *rightBarView;

@end


@implementation CHHeaderView

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = HEX_COLOR(0x1B1B1B);
        self.translatesAutoresizingMaskIntoConstraints = NO;
        
        [self addSubview:self.titleLabel];
    }
    return self;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _titleLabel.font = [UIFont systemFontOfSize:20.0 weight:UIFontWeightSemibold];
        _titleLabel.textColor = [UIColor whiteColor];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _titleLabel;
}

- (void)setTitle:(NSString *)title {
    self.titleLabel.text = title;
}

- (void)setLeftBarView:(UIView *)view {
    [self.leftBarView removeFromSuperview];
    
    _leftBarView = view;
    [self addSubview:_leftBarView];
    
    [self setNeedsLayout];
}

- (void)setRightBarView:(UIView *)view {
    [self.rightBarView removeFromSuperview];
    
    _rightBarView = view;
    [self addSubview:_rightBarView];
    
    [self setNeedsLayout];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat leftSideViewWidth = self.leftBarView.bounds.size.width;
    CGFloat rightSideViewWidth = self.rightBarView.bounds.size.width;
    CGFloat sideViewMaxWidth = MAX(leftSideViewWidth, rightSideViewWidth);
    
    self.titleLabel.frame = CGRectInset(self.bounds, sideViewMaxWidth, 0.0);
    [self.titleLabel setX:sideViewMaxWidth];
    [self.titleLabel setWidth:self.bounds.size.width - 2 * sideViewMaxWidth];
    [self.titleLabel setHeight:50];
    [self.titleLabel setY:self.bounds.size.height - 50];

    [self.rightBarView setX:self.bounds.size.width - sideViewMaxWidth];
    [self.rightBarView setY:self.bounds.size.height - self.rightBarView.bounds.size.height];

    [self.leftBarView setX:0.0];
    [self.leftBarView setY:self.bounds.size.height - self.leftBarView.bounds.size.height];
}

@end
