#import "CHFriendListDataSource.h"

#import "CHFriendCell.h"
#import "CHDatabase.h"

@interface CHFriendListDataSource ()

@property (nonatomic, strong) NSArray *allFriends;

@end


@implementation CHFriendListDataSource

#pragma mark -
#pragma mark Properties

- (NSMutableSet *)selectedFriends {
    if (!_selectedFriends) {
        _selectedFriends = [NSMutableSet set];
    }
    return _selectedFriends;
}


#pragma mark -
#pragma mark Public

- (void)fetchFriends {
    [CHDatabase fetchAllPeopleWithCompletion:^(NSArray *friends) {
        self.allFriends = [friends sortedArrayUsingComparator:^NSComparisonResult(CHPerson *person1, CHPerson *person2) {
            return [person1.fullName compare:person2.fullName];
        }];
        [self.delegate friendListDataSource:self didUpdateFriendList:friends];
    }];
}

- (NSInteger)numberOfPeople {
    return self.allFriends.count;
}

- (CHPerson *)personAtIndex:(NSInteger)index {
    return self.allFriends[index];
}


#pragma mark -
#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self numberOfPeople];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *reuseIdentifier = @"friendCell";
    CHFriendCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    if (!cell) {
        cell = [[CHFriendCell alloc] initWithReuseIdentifier:reuseIdentifier];
    }
    
    CHPerson *friend = [self personAtIndex:indexPath.row];
    [cell setFriend:friend];
    
    [cell setChosen:[self.selectedFriends containsObject:friend]];
    
    return cell;
}

@end
