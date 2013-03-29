#import "CHStoryListViewController.h"
#import "CHConstants.h"
#import "CHStoryListCell.h"
#import "CHStoryListHeaderView.h"
#import "CHCloud.h"
#import "CHDatabase.h"
#import "CHStoryListDataSource.h"
#import <RGInterfaceKit/RGInterfaceKit.h>

#define kCellHeight 154.0

static NSString * const kStoryCellReuseID = @"story-cell";

@interface CHStoryListViewController ()<UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, CHStoryListDataSourceDelegate, UIAlertViewDelegate, CHStoryListHeaderViewDelegate>

@property (nonatomic, strong) CHStoryListHeaderView *headerView;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) CHStoryListDataSource *dataSource;
@property (nonatomic, strong) NSArray *stories;

@end

@implementation CHStoryListViewController

#pragma mark -
#pragma mark View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    [self.view setBackgroundColor:HEX_COLOR(0x1B1B1B)];

    [self.headerView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.view addSubview:self.headerView];
    [self.headerView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor].active = YES;
    [self.headerView.leftAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leftAnchor].active = YES;
    [self.headerView.rightAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.rightAnchor].active = YES;
    [self.headerView.heightAnchor constraintEqualToConstant:50].active = YES;

    [self.collectionView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.view addSubview:self.collectionView];
    [self.collectionView.topAnchor constraintEqualToAnchor:self.headerView.bottomAnchor].active = YES;
    [self.collectionView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor].active = YES;
    [self.collectionView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor].active = YES;
    [self.collectionView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor].active = YES;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    self.dataSource = [[CHStoryListDataSource alloc] init];
    self.dataSource.delegate = self;
}


#pragma mark - Properties

- (CHHeaderView *)headerView {
    if (!_headerView) {
        _headerView = [[CHStoryListHeaderView alloc] init];
        _headerView.delegate = self;
    }
    return _headerView;
}

- (UICollectionView *)collectionView {
    if (!_collectionView) {
        UICollectionViewFlowLayout *layout = [UICollectionViewFlowLayout new];
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
        [_collectionView setAlwaysBounceVertical:YES];
        [_collectionView setDataSource:self];
        [_collectionView setDelegate:self];
        
        [_collectionView registerClass:[CHStoryListCell class] forCellWithReuseIdentifier:kStoryCellReuseID];
        
        UILongPressGestureRecognizer *press = [UILongPressGestureRecognizer new];
        [press addTarget:self action:@selector(onLongPress:)];
        [_collectionView addGestureRecognizer:press];
    }
    return _collectionView;
}


#pragma mark - CHStoryListDataSourceDelegate

- (void)storyListDataSource:(CHStoryListDataSource *)dataSource
           didUpdateResults:(NSArray *)results {
    
    self.stories = results;
    [self.collectionView reloadData];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.stories.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    CHStoryListCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kStoryCellReuseID forIndexPath:indexPath];

    CHStory *story = [self.stories objectAtIndex:indexPath.item];
    [cell setStory:story];
    
    return cell;
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return 0.0;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsZero;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return 0.5;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(collectionView.frameWidth, kCellHeight);
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    CHStory *story = [self.stories objectAtIndex:indexPath.item];
    [self.delegate storyListViewController:self didSelectStory:story];
}

#pragma mark - CHStoryListHeaderViewDelegate

- (void)storyListHeaderView:(CHStoryListHeaderView *)viewController didAddStory:(CHStory *)story {
    [self.delegate storyListViewController:self didSelectStory:story];
}

#pragma mark - Action Listeners

- (void)onLongPress:(UILongPressGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        CGPoint point = [recognizer locationInView:self.collectionView];
        NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:point];
        if (!indexPath) {
            return;
        }

        CHStory *story = [self.stories objectAtIndex:indexPath.item];
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Delete Story?" message:@"This action cannot be undone!" preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            //
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            [CHDatabase deleteStory:story];
        }]];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

@end
