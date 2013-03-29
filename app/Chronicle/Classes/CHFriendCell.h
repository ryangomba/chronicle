#import <UIKit/UIKit.h>
#import "CHPerson.h"

@interface CHFriendCell : UITableViewCell

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier;

@property (nonatomic, strong) CHPerson *friend;
@property (nonatomic, assign) BOOL chosen;

@end
