#import "CHDirectedViewController.h"
#import "CHPerson.h"

@class CHAddFriendViewController;
@protocol CHAddFriendViewControllerDelegate <NSObject>

- (void)addFriendViewController:(CHAddFriendViewController *)viewCotroller didAddFriend:(CHPerson *)friend;
- (void)addFriendViewController:(CHAddFriendViewController *)viewCotroller didRemoveFriend:(CHPerson *)friend;

@end

@interface CHAddFriendViewController : CHDirectedViewController

@property (nonatomic, weak) id<CHAddFriendViewControllerDelegate> delegate;

- (id)initWithSelectedFriends:(NSArray *)selectedFriends;

@end
