#import <UIKit/UIKit.h>
#import "CHPerson.h"

@interface CHFriendView : UIView

@property (nonatomic, strong, readonly) CHPerson *friend;

- (id)initWithFriend:(CHPerson *)friend avatarSize:(CGFloat)avatarSize;

- (void)setTarget:(id)target action:(SEL)action;

@end
