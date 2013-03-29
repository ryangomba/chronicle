#import <UIKit/UIKit.h>
#import "CHPerson.h"

@class CHFriendListDataSource;
@protocol CHFriendListDataSourceDelegate <NSObject>

- (void)friendListDataSource:(CHFriendListDataSource *)dataSource
         didUpdateFriendList:(NSArray *)friends;

@end

@interface CHFriendListDataSource : NSObject<UITableViewDataSource>

@property (nonatomic, strong) NSMutableSet *selectedFriends;

@property (nonatomic, weak) id<CHFriendListDataSourceDelegate> delegate;

- (void)fetchFriends;

- (NSInteger)numberOfPeople;
- (CHPerson *)personAtIndex:(NSInteger)index;

@end
