    #import "CHFriendsTrayCell.h"
#import <RGNetworking/RGNetworking.h>
#import "CHAddFriendView.h"
#import "CHFriendView.h"
#import "CHDatabase.h"
#import "CHStoryMembersDataSource.h"
#import "CHConstants.h"
#import <RGInterfaceKit/RGInterfaceKit.h>

#define kFriendsKeyPath @"friends"
#define kAvatarSpacing 5.0

@interface CHFriendsTrayCell ()<CHStoryMembersDataSourceDelegate>

@property (nonatomic, strong) CHStoryMembersDataSource *dataSource;
@property (nonatomic, strong) NSArray *people;
@property (nonatomic, strong) NSArray *friendViews;

@property (nonatomic, strong) RGImageView *currentUserView;
@property (nonatomic, strong) CHAddFriendButton *addFriendButton;

@property (nonatomic, strong, readwrite) UIView *trayView;

@end


@implementation CHFriendsTrayCell

#pragma mark -
#pragma mark NSObject

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {        
        [self setClipsToBounds:YES];
        [self setAvatarSize:kCHAvatarSize];
        
        self.trayView = [[UIView alloc] initWithFrame:self.bounds];
        [self.trayView setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
        [self.contentView addSubview:self.trayView];
    }
    return self;
}


#pragma mark -
#pragma mark Properties

- (void)setStory:(CHStory *)story {
    _story = story;

    self.dataSource = [[CHStoryMembersDataSource alloc] initWithStory:self.story];
    self.dataSource.delegate = self;
}

- (RGImageView *)currentUserView {
    if (!_currentUserView) {
        _currentUserView = [[RGImageView alloc] initWithFrame:CGRectZero];
        
        // TODO: implement
        // [_currentUserView setImageURL:url];
    }
    return _currentUserView;
}

- (CHAddFriendButton *)addFriendButton {
    if (!_addFriendButton) {
        _addFriendButton = [[CHAddFriendButton alloc] initWithFrame:CGRectZero];
        [_addFriendButton addTarget:self
                             action:@selector(onAddFriendTapped)
                   forControlEvents:UIControlEventTouchUpInside];
    }
    return _addFriendButton;
}

- (CGPoint)caretPosition {
    return CGPointMake(self.addFriendButton.center.x, kCHTrayHeight - 6.0);
}


#pragma mark -
#pragma mark Class Methods

+ (CGFloat)heightWithAvatarSize:(CGFloat)avatarSize {
    return avatarSize;
}


#pragma mark -
#pragma mark CHStoryMembersDataSourceDelegate

- (void)storyMembersDataSource:(CHStoryMembersDataSource *)dataSource
              didUpdateResults:(NSArray *)results {
    
    self.people = results;
    [self doLayout];
}


#pragma mark -
#pragma mark Private

- (void)doLayout {
    [self.friendViews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    NSMutableArray *friendViews = [NSMutableArray array];
    
    [self.currentUserView setSize:CGSizeMake(self.avatarSize, self.avatarSize)];
    [friendViews addObject:self.currentUserView];
    [self.trayView addSubview:self.currentUserView];

    for (CHPerson *person in self.people) {
        CHFriendView *friendView = [[CHFriendView alloc] initWithFriend:person avatarSize:self.avatarSize];
        [friendView setTarget:self action:@selector(onFriendViewTapped:)];
        [friendViews addObject:friendView];
        [self.trayView addSubview:friendView];
    }

    [self.addFriendButton setSize:CGSizeMake(self.avatarSize, self.avatarSize)];
    [friendViews addObject:self.addFriendButton];
//    [self.trayView addSubview:self.addFriendButton];

    [self setFriendViews:friendViews];
    [self setNeedsLayout];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    NSInteger x = 0;
    NSInteger y = 0;
    for (UIView *friendView in self.friendViews) {
        [friendView setOrigin:CGPointMake(x, y)];
        x += self.avatarSize + kAvatarSpacing;
    }
}


#pragma mark -
#pragma mark Button Listeners

- (void)onAddFriendTapped {
    [self.delegate friendCell:self didTapAddFriendButtonWithExistingFriends:self.people];
}

- (void)onFriendViewTapped:(CHFriendView *)friendView {
    [self.delegate friendCell:self didSelectFriend:friendView.friend];
}

@end
