#import "CHFriendView.h"
#import <RGNetworking/RGNetworking.h>
#import <QuartzCore/QuartzCore.h>
#import "CHConstants.h"

@interface CHFriendView ()

@property (nonatomic, strong, readwrite) CHPerson *friend;

@property (nonatomic, strong) RGImageView *imageView;
@property (nonatomic, strong) UIButton *button;

@property (nonatomic, weak) id target;
@property (nonatomic, assign) SEL action;

@end


@implementation CHFriendView

- (id)initWithFriend:(CHPerson *)friend avatarSize:(CGFloat)avatarSize {
    CGRect frame = CGRectMake(0, 0, avatarSize, avatarSize);
    if (self = [super initWithFrame:frame]) {
        [self setFriend:friend];
        
        [self addSubview:self.imageView];
        [self addSubview:self.button];
    }
    return self;
}

- (RGImageView *)imageView {
    if (!_imageView) {
        _imageView = [[RGImageView alloc] initWithFrame:self.bounds];
        
        [_imageView.layer setBorderColor:kCHBorderColor.CGColor];
        [_imageView.layer setBorderWidth:0.5f];
    }
    return _imageView;
}

- (UIButton *)button {
    if (!_button) {
        _button = [[UIButton alloc] initWithFrame:self.bounds];
        [_button addTarget:self action:@selector(onButtonTapped) forControlEvents:UIControlEventTouchUpInside];
        
        [_button.imageView setContentMode:UIViewContentModeCenter];
    }
    return _button;
}

- (void)setFriend:(CHPerson *)friend {
    _friend = friend;
    
    NSInteger avatarImageSize = kCHAvatarSize * [UIScreen mainScreen].scale;
    NSURL *avatarURL = [self.friend avatarURLForImageOfSize:avatarImageSize];
    [self.imageView setImageURL:avatarURL];
}

- (void)setTarget:(id)target action:(SEL)action {
    [self setTarget:target];
    [self setAction:action];
}

- (void)onButtonTapped {
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [self.target performSelector:self.action withObject:self];
    #pragma clang diagnostic pop
}

@end
