#import <UIKit/UIKit.h>
#import "CHPerson.h"
#import "CHStory.h"

@class CHFriendsTrayCell;
@protocol CHFriendsTrayCellDelegate <NSObject>

- (void)friendCell:(CHFriendsTrayCell *)friendCell didSelectFriend:(CHPerson *)friend;
- (void)friendCell:(CHFriendsTrayCell *)friendCell didTapAddFriendButtonWithExistingFriends:(NSArray *)friends;

@end


@interface CHFriendsTrayCell : UICollectionViewCell

@property (nonatomic, strong) CHStory *story;

@property (nonatomic, assign) CGFloat avatarSize;
@property (nonatomic, readonly) CGPoint caretPosition;
@property (nonatomic, strong, readonly) UIView *trayView;

@property (nonatomic, weak) id<CHFriendsTrayCellDelegate> delegate;

+ (CGFloat)heightWithAvatarSize:(CGFloat)avatarSize;

@end
