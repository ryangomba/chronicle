#import "CHAddFriendViewController.h"
#import "CHConstants.h"
#import "CHFriendCell.h"
#import "CHFriendListDataSource.h"

@interface CHAddFriendViewController ()<UITableViewDelegate, CHFriendListDataSourceDelegate>

@property (nonatomic, strong) CHFriendListDataSource *dataSource;

@property (nonatomic, strong) UITableView *tableView;

@end


@implementation CHAddFriendViewController

#pragma mark -
#pragma mark NSObject

- (id)initWithSelectedFriends:(NSArray *)selectedFriends {
    if (self = [super initWithNibName:nil bundle:nil]) {
        NSMutableSet *selectedFriendsSet = [NSMutableSet setWithArray:selectedFriends];
        [self.dataSource setSelectedFriends:selectedFriendsSet];
        
        [self setTitle:NSLocalizedString(@"Add Friend", nil)];
    }
    return self;
}


#pragma mark -
#pragma mark View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.layer.shadowColor = [UIColor blackColor].CGColor;
    self.view.layer.shadowOffset = CGSizeZero;
    self.view.layer.shadowOpacity = 0.3;
    self.view.layer.shadowRadius = 1.0;
    self.view.layer.shadowPath = [UIBezierPath bezierPathWithRect:self.view.bounds].CGPath;
    
    [self.tableView setFrame:self.view.bounds];
    [self.view addSubview:self.tableView];
    
    [self.dataSource fetchFriends];
}


#pragma mark -
#pragma mark Properties

- (CHFriendListDataSource *)dataSource {
    if (!_dataSource) {
        _dataSource = [[CHFriendListDataSource alloc] init];
        _dataSource.delegate = self;
    }
    return _dataSource;
}

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero];
        [_tableView setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
        [_tableView setSeparatorColor:HEX_COLOR(0xdddddd)];
        [_tableView setSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];
        [_tableView setDataSource:self.dataSource];
        [_tableView setDelegate:self];
    }
    return _tableView;
}


#pragma mark -
#pragma mark CHFriendListDataSourceDelegate

- (void)friendListDataSource:(CHFriendListDataSource *)dataSource
         didUpdateFriendList:(NSArray *)friends {
    
    [self.tableView reloadData];
}


#pragma mark -
#pragma mark UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return kCHAvatarSize;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    CHPerson *friend = [self.dataSource personAtIndex:indexPath.row];
    
    if ([self.dataSource.selectedFriends containsObject:friend]) {
        [self.dataSource.selectedFriends removeObject:friend];
        [self.delegate addFriendViewController:self didRemoveFriend:friend];
        
    } else {
        [self.dataSource.selectedFriends addObject:friend];
        [self.delegate addFriendViewController:self didAddFriend:friend];
        
        [self.tableView reloadData];
    }
    
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
}

@end
