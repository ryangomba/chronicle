#import "CHStoryListHeaderView.h"

#import "CHDatabase.h"
#import "CHFileUploadManager.h"

@interface CHStoryListHeaderView ()

@property (nonatomic, strong) UIButton *operationCountButton;
@property (nonatomic, strong) UIButton *newButton;

@end

@implementation CHStoryListHeaderView

- (instancetype)init {
    if (self = [super init]) {
        [self setTitle:@"Stories"];
//        [self setLeftBarView:self.operationCountButton];
        [self setRightBarView:self.newButton];
    }
    return self;
}

#pragma mark - Buttons

- (UIButton *)operationCountButton {
    if (!_operationCountButton) {
        _operationCountButton = [[UIButton alloc] initWithFrame:CGRectMake(0.0, 0.0, 50, 50)];
        [_operationCountButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _operationCountButton.titleLabel.textAlignment = NSTextAlignmentCenter;
        [[CHFileUploadManager sharedSyncManager] addObserver:self
                                                  forKeyPath:@"ongoingOperationCount"
                                                     options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew
                                                     context:NULL];
    }
    return _operationCountButton;
}

- (UIButton *)newButton {
    if (!_newButton) {
        _newButton = [[UIButton alloc] initWithFrame:CGRectMake(0.0, 0.0, 50, 50)];
        [_newButton setTitle:@"+" forState:UIControlStateNormal];
        _newButton.titleLabel.font = [UIFont systemFontOfSize:30.0 weight:UIFontWeightLight];
        [_newButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_newButton addTarget:self action:@selector(onNewButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    }
    return _newButton;
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *count = [NSString stringWithFormat:@"%lu", (long)[object ongoingOperationCount]];
        [self.operationCountButton setTitle:count forState:UIControlStateNormal];
    });
}

#pragma mark - Actions

- (void)onNewButtonTapped {
    CHStory *story = [CHStory newStory];
    [CHDatabase addStory:story];
    [self.delegate storyListHeaderView:self didAddStory:story];
}

@end
