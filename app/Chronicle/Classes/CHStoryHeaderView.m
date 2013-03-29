#import "CHStoryHeaderView.h"

#import "CHDatabase.h"
#import "CHFileUploadManager.h"

static NSString * const kWebRoot = @"https://chronicle.appthat.com"; // TODO move this

@interface CHStoryHeaderView ()

@property (nonatomic, strong) CHStory *story;
@property (nonatomic, strong) UIButton *backButton;
@property (nonatomic, strong) UIButton *shareButton;

@end

@implementation CHStoryHeaderView

- (instancetype)initWithStory:(CHStory *)story {
    if (self = [super init]) {
        self.story = story;

        [self setLeftBarView:self.backButton];
        [self setRightBarView:self.shareButton];
    }
    return self;
}

#pragma mark - Buttons

- (UIButton *)backButton {
    if (!_backButton) {
        _backButton = [[UIButton alloc] initWithFrame:CGRectMake(0.0, 0.0, 50, 50)];
        [_backButton setImage:[UIImage imageNamed:@"back.png"] forState:UIControlStateNormal];
        [_backButton addTarget:self action:@selector(onBackButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    }
    return _backButton;
}

- (UIButton *)shareButton {
    if (!_shareButton) {
        _shareButton = [[UIButton alloc] initWithFrame:CGRectMake(0.0, 0.0, 50, 50)];
        [_shareButton setImage:[UIImage imageNamed:@"share.png"] forState:UIControlStateNormal];
        [_shareButton addTarget:self action:@selector(onShareButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    }
    return _shareButton;
}

#pragma mark - Actions

- (void)onBackButtonTapped {
    [self.delegate storyHeaderViewDidDismiss:self];
}

- (void)onShareButtonTapped {
    NSString *URLString = [NSString stringWithFormat:@"%@/stories/%@", kWebRoot, self.story.pk];
    NSURL *URL = [NSURL URLWithString:URLString];
    [[UIApplication sharedApplication] openURL:URL options:@{} completionHandler:nil];
}

@end
