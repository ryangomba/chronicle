#import "CHAddBitButton.h"

#define kSize 56

@interface CHAddBitButton ()

@property (nonatomic, strong) UIButton *mainButton;

@end

@implementation CHAddBitButton

+ (CGSize)size {
    return CGSizeMake(kSize, kSize);
}

- (instancetype)init {
    if (self = [super initWithFrame:CGRectMake(0, 0, self.class.size.width, self.class.size.height)]) {
        [self addSubview:self.mainButton];
    }
    return self;
}

#pragma mark - Buttons

- (UIButton *)mainButton {
    if (!_mainButton) {
        _mainButton = [[UIButton alloc] initWithFrame:self.bounds];
        _mainButton = [[UIButton alloc] initWithFrame:self.bounds];
        [_mainButton setBackgroundColor:[UIColor whiteColor]];
        [_mainButton.layer setCornerRadius:kSize / 2];
        [_mainButton.layer setShadowColor:[UIColor blackColor].CGColor];
        [_mainButton.layer setShadowOpacity:0.2];
        [_mainButton.layer setShadowRadius:10];
        [_mainButton.layer setShadowOffset:CGSizeMake(0, 2)];
        [_mainButton setTitle:@"+" forState:UIControlStateNormal];
        _mainButton.titleLabel.font = [UIFont systemFontOfSize:36.0 weight:UIFontWeightRegular];
        _mainButton.titleEdgeInsets = UIEdgeInsetsMake(0, 0, 5, 0); // visually center
        [_mainButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [_mainButton addTarget:self action:@selector(onAddButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    }
    return _mainButton;
}

#pragma mark - Actions

- (void)onAddButtonTapped {
    [self.delegate addBitButton:self];
}

@end
