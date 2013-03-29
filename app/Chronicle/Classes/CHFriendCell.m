#import "CHFriendCell.h"
#import "CHConstants.h"
#import <QuartzCore/QuartzCore.h>
#import "CHFriendView.h"
#import <RGInterfaceKit/RGInterfaceKit.h>

@interface CHFriendCell ()

@property (nonatomic, strong) CHFriendView *friendView;


@end


@implementation CHFriendCell

#pragma mark -
#pragma mark NSObject

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier]) {
        [self setSelectionStyle:UITableViewCellSelectionStyleNone];
    }
    return self;
}


#pragma mark -
#pragma mark Properties

- (CHFriendView *)friendView {
    if (!_friendView) {
        _friendView = [[CHFriendView alloc] initWithFriend:self.friend avatarSize:kCHAvatarSize];
    }
    return _friendView;
}

- (void)setFriend:(CHPerson *)friend {
    _friend = friend;
     
    [self.textLabel setText:friend.fullName];
    
    [self.friendView removeFromSuperview];
    [self setFriendView:nil];
    [self.contentView addSubview:self.friendView];
    [self setNeedsLayout];
}

- (void)setChosen:(BOOL)chosen {
    _chosen = chosen;
    
    [self.textLabel setTextColor:_chosen ? kCHHighlightColor : kCHDefaultTextColor];
}


#pragma mark -
#pragma mark Private

- (void)layoutSubviews {
    [super layoutSubviews];
    
    NSInteger textLabelX = kCHAvatarSize + kCHDefaultPadding;
    [self.textLabel setFrame:CGRectMake(textLabelX, 0, self.contentView.frameWidth - textLabelX, self.contentView.frameHeight)];
}

@end
