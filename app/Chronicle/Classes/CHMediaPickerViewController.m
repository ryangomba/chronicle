#import "CHMediaPickerViewController.h"

#import "CHTransformableCell.h"
#import "CHPhotosLayoutManager.h"
#import <RGFoundation/RGFoundation.h>
#import "CHPhotoViewSource.h"
#import "CHAssetImageSource.h"
#import "CHAssetsLibraryImporter.h"
#import "CHDatabase.h"

@interface CHMediaPickerViewController ()<UICollectionViewDataSource, UICollectionViewDelegate, RGTransformableViewDelegate>

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) CHPhotosLayoutManager *layoutManager;

@property (nonatomic, strong) NSArray *allAssets;
@property (nonatomic, strong) CHPhotoViewSource *photoViewSource;

@property (nonatomic, weak) RGTransformableView *draggedView;
@property (nonatomic, strong) CHPhoto *draggedPhoto;

@end


@implementation CHMediaPickerViewController

#pragma mark -
#pragma mark NSObject

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)init {
    if (self = [super init]) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fetchData) name:@"assets-did-change" object:nil];
    }
    return self;
}


#pragma mark -
#pragma mark View Lifecyle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.collectionView.frame = self.view.bounds;
    [self.view addSubview:self.collectionView];

    [self performInNextRunLoop:^{
        [self fetchData];
    }];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];

    if (self.draggedPhoto) {
        NSIndexPath *indexPath = [self indexPathForPhoto:self.draggedPhoto];
        CHTransformableCell *cell = (id)[self.collectionView cellForItemAtIndexPath:indexPath];
        [self configureCell:cell atIndexPath:indexPath];
    }
}


#pragma mark -
#pragma mark Properties

- (UICollectionView *)collectionView {
    if (!_collectionView) {
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:self.layoutManager.layout];
        [_collectionView setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
        [_collectionView setContentInsetAdjustmentBehavior:UIScrollViewContentInsetAdjustmentNever];
        [_collectionView setShowsVerticalScrollIndicator:NO];
        [_collectionView setAlwaysBounceVertical:YES];
        [_collectionView setDelaysContentTouches:NO];
        [_collectionView setDataSource:self];
        [_collectionView setDelegate:self];
    }
    return _collectionView;
}

- (CHPhotosLayoutManager *)layoutManager {
    if (!_layoutManager) {
        _layoutManager = [[CHPhotosLayoutManager alloc] init];
        [_layoutManager setDensity:CHPhotosLayoutDensityNormal];
        _layoutManager.margin = 0.0;
        _layoutManager.spacing = 1.0;
    }
    return _layoutManager;
}

- (CHPhotoViewSource *)photoViewSource {
    if (!_photoViewSource) {
        _photoViewSource = [[CHPhotoViewSource alloc] init];
    }
    return _photoViewSource;
}


#pragma mark -
#pragma mark Public

- (void)fetchData {
    self.allAssets = [CHAssetsLibraryImporter sharedImporter].allAssets;
    [self.collectionView reloadData];
    
    [self scrollToBottom];
}

- (void)invalidateLayout {
    [self.layoutManager invalidateLayout];
}


#pragma mark -
#pragma mark Private

- (void)scrollToBottom {
    [self.collectionView layoutIfNeeded];
    
    CGFloat contentHeight = self.collectionView.contentSize.height;
    CGFloat contentOffsetY = contentHeight - self.collectionView.bounds.size.height;
    CGPoint contentOffset = CGPointMake(0.0, contentOffsetY);
    [self.collectionView setContentOffset:contentOffset animated:NO];
}


#pragma mark -
#pragma mark UICollectionViewDataSource

- (NSIndexPath *)indexPathForPhoto:(CHPhoto *)photo {
    return [NSIndexPath indexPathForItem:[self.allAssets indexOfObject:photo] inSection:0];
}

- (CHPhoto *)photoAtIndexPath:(NSIndexPath *)indexPath {
    return [self.allAssets objectAtIndex:indexPath.row];
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.allAssets.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    CHPhoto *photo = [self photoAtIndexPath:indexPath];
    
    [self.collectionView registerClass:[CHTransformableCell class] forCellWithReuseIdentifier:photo.pk];
    CHTransformableCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:photo.pk
                                                                  forIndexPath:indexPath];
    
    [self configureCell:cell atIndexPath:indexPath];
    
    return cell;
}

- (void)configureCell:(CHTransformableCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    CHPhoto *photo = [self photoAtIndexPath:indexPath];

    CHFramedImageView *imageView = [self.photoViewSource viewForPhoto:photo];
    [self passControlOfImageView:imageView toCell:cell animated:NO];

    if (photo.isFavorite) {
        cell.layer.borderColor = [UIColor redColor].CGColor;
        cell.layer.borderWidth = 4.0;
    } else {
        cell.layer.borderColor = NULL;
        cell.layer.borderWidth = 0.0;
    }
}


#pragma mark -
#pragma mark UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    return [self.layoutManager sizeForItemAtIndexPath:indexPath];
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView
                        layout:(UICollectionViewLayout *)collectionViewLayout
        insetForSectionAtIndex:(NSInteger)section {
    
    return [self.layoutManager insetForSectionAtIndex:section];
}

- (CGFloat)collectionView:(UICollectionView *)collectionView
                   layout:(UICollectionViewLayout *)collectionViewLayout
minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    
    return [self.layoutManager minimumLineSpacingForSectionAtIndex:section];
}

- (CGFloat)collectionView:(UICollectionView *)collectionView
                   layout:(UICollectionViewLayout *)collectionViewLayout
minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    
    return [self.layoutManager minimumInteritemSpacingForSectionAtIndex:section];
}


#pragma mark -
#pragma mark Control

- (void)passControlOfImageView:(CHFramedImageView *)imageView
                        toCell:(CHTransformableCell *)cell
                      animated:(BOOL)animated {
    
    [imageView setDelegate:self];
    [imageView setDesiredSize:cell.bounds.size];
    [imageView setDesiredCenter:CGRectGetMiddle(cell.frame) inTargetView:cell.contentView];
    [imageView setPhoto:imageView.photo desiredImageSize:CHPhotoImageSizeThumbnail];
    [imageView moveToDesiredPositionAnimated:animated];
    
    [cell setTransformableView:imageView];
}


#pragma mark -
#pragma mark RGTransformableViewDelegate
// TODO don't like this here

- (BOOL)transformableViewShouldReceieveLongPress:(RGTransformableView *)view {
    return YES;
}

- (void)transformableViewDidReceieveLongPress:(RGTransformableView *)view {
    self.draggedView = view;
    self.draggedPhoto = ((CHPhotoView *)view).photo;

    // HACK
    self.collectionView.panGestureRecognizer.enabled = NO;
    self.collectionView.panGestureRecognizer.enabled = YES;
    
    [self.delegate mediaPickerViewController:self
                       willBeginDraggingView:view
                                    forPhoto:((CHPhotoView *)view).photo];
    
    // TODO remove photo from list
}

- (BOOL)transformableViewShouldTranslateX:(RGTransformableView *)view {
    return view == self.draggedView;
}

- (BOOL)transformableViewShouldTranslateY:(RGTransformableView *)view {
    return view == self.draggedView;
}

@end
