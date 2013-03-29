#import "CHAddFriendView.h"

@implementation CHAddFriendButton

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        UIImage *backgroundImage = [UIImage imageNamed:@"audience-friends.png"];
        [self setBackgroundImage:backgroundImage forState:UIControlStateNormal];
    }
    return self;
}

@end
