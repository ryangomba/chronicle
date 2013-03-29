#import "CHStoryViewController.h"

#import "CHFriendsTrayCell.h"
#import "CHTransformableCell.h"
#import "CHNavigationController.h"
#import "CHStoryHeaderView.h"
#import "CHPhotoViewSource.h"
#import "CHStoryListCell.h"
#import "RGInteractiveCollectionViewLayout.h"
#import "CHBitPickerViewController.h"
#import "CHDatabase.h"
#import "CHAddBitButton.h"
#import "CHKeyboardManager.h"
#import "CHFramedVideoView.h"
#import <RGCore/RGCore.h>
#import <RGFoundation/RGFoundation.h>
#import <POP/POP.h>
#import <POP/POPLayerExtras.h>
#import "CHConstants.h"
#import <RGInterfaceKit/RGInterfaceKit.h>

static NSString * const kFooterReuseIdentifier = @"footer";
static NSString * const kFriendsCellReuseIdentifier = @"friends-cell";
static NSString * const kExpandableCellReuseIdentifier = @"expandable-cell";

typedef NS_ENUM(NSInteger, StorySection) {
    StorySectionFriends,
    StorySectionBits,
    StorySectionCount,
};

#define kCellPadding 20.0

@interface CHStoryViewController ()<UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, CHFriendsTrayCellDelegate, CHTransformableTextViewDelegate, RGInteractiveCollectionViewLayoutDelegate, UIGestureRecognizerDelegate, CHBitPickerViewControllerDelegate, RGTransformableViewDelegate, CHKeyboardManagerDelegate, CHStoryHeaderViewDelegate, CHAddBitButtonDelegate>

@property (nonatomic, strong, readwrite) CHStory *story;
@property (nonatomic, strong) NSArray *bits;

@property (nonatomic, strong) CHStoryHeaderView *headerView;
@property (nonatomic, strong, readwrite) UICollectionView *collectionView;
@property (nonatomic, strong) RGInteractiveCollectionViewLayout *layout;
@property (nonatomic, strong) CHPhotoViewSource *photoViewSource;
@property (nonatomic, strong) CHTextViewSource *textViewSource;

@property (nonatomic, weak) UIView *extractedView;
@property (nonatomic, weak) UIView *extractedViewSuperview;
@property (nonatomic, assign) CGPoint extractedViewCenter;
@property (nonatomic, weak) UICollectionViewCell *dropCell;

@property (nonatomic, assign) BOOL isEditing;
@property (nonatomic, strong) CHKeyboardManager *keyboardManager;

@property (nonatomic, weak) RGTransformableView *draggedView;
@property (nonatomic, assign) BOOL draggedViewIsNew;
@property (nonatomic, weak) CHTransformableTextView *editingView;

@property (nonatomic, strong) NSIndexPath *newlyAddedIndexPath;
@property (nonatomic, assign) CGFloat newlyAddedIndexPathHeight;

@property (nonatomic, assign) CGFloat desiredHeightForActiveTextCell;

@end

@implementation CHStoryViewController

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [self.collectionView setDataSource:nil];
    [self.collectionView setDelegate:nil];
}

- (id)initWithStory:(CHStory *)story {
    if (self = [super initWithNibName:nil bundle:nil]) {
        [self setStory:story];
        
        self.keyboardManager = [[CHKeyboardManager alloc] init];
        self.keyboardManager.scrollView = self.collectionView;
        self.keyboardManager.delegate = self;
        
        // TODO be more specific!
        weakify(self);
        [[NSNotificationCenter defaultCenter] addObserverForName:kCHNotificationBitModifiedExternally
                                                          object:nil
                                                           queue:nil
                                                      usingBlock:^(NSNotification *notification)
        {
            strongify(self);
            CHBit *newBit = notification.object;
            NSInteger bitIndex = [self.bits indexOfObject:newBit];
            if (bitIndex != NSNotFound) {
                NSMutableArray *bits = [self.bits mutableCopy];
                [bits replaceObjectAtIndex:bitIndex withObject:newBit];
                self.bits = [bits copy];
            }
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:bitIndex inSection:StorySectionBits];
            [self.collectionView reloadItemsAtIndexPaths:@[indexPath]];
        }];
    }
    return self;
}

#pragma mark - View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];

    CGRect headerRect = CGRectMake(0, 0, self.view.bounds.size.width, 42 + 50); // HACK
    [self.headerView setFrame:headerRect];
    [self.view addSubview:self.headerView];

    CGRect collectionViewRect = CGRectMake(0, CGRectGetMaxY(headerRect), self.view.bounds.size.width, self.view.bounds.size.height - CGRectGetMaxY(headerRect));
    UIView *wrapperView = [[UIView alloc] init];
    [wrapperView setFrame:collectionViewRect];
    [self.view insertSubview:wrapperView belowSubview:self.headerView];
    [self.collectionView setFrame:wrapperView.bounds];
    [wrapperView addSubview:self.collectionView];

    CHAddBitButton *addBitButton = [[CHAddBitButton alloc] init];
    addBitButton.delegate = self;
    [addBitButton setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.view addSubview:addBitButton];
    [addBitButton.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor constant:-kCHDefaultPadding].active = YES;
    [addBitButton.rightAnchor constraintEqualToAnchor:self.view.rightAnchor constant:-kCHDefaultPadding].active = YES;
    [addBitButton.heightAnchor constraintEqualToConstant:[CHAddBitButton size].height].active = YES;
    [addBitButton.widthAnchor constraintEqualToConstant:[CHAddBitButton size].width].active = YES;

    [CHDatabase fetchAllBitsForStory:self.story completion:^(NSArray *bits) {
        self.bits = bits;
        [self.collectionView reloadData];
    }];
}

#pragma mark - Properties

- (CHStoryHeaderView *)headerView {
    if (!_headerView) {
        _headerView = [[CHStoryHeaderView alloc] initWithStory:self.story];
        _headerView.delegate = self;
    }
    return _headerView;
}

- (RGInteractiveCollectionViewLayout *)layout {
    if (!_layout) {
        _layout = [[RGInteractiveCollectionViewLayout alloc] init];
        _layout.specialLayoutDelegate = self;
    }
    return _layout;
}

- (UICollectionView *)collectionView {
    if (!_collectionView) {
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:self.layout];
        [_collectionView setBackgroundColor:[UIColor whiteColor]];
        [_collectionView setContentInsetAdjustmentBehavior:UIScrollViewContentInsetAdjustmentNever];
        [_collectionView setKeyboardDismissMode:UIScrollViewKeyboardDismissModeInteractive];
        [_collectionView setAlwaysBounceVertical:YES];
        [_collectionView setDataSource:self];
        [_collectionView setDelegate:self];

        [_collectionView registerClass:[UICollectionViewCell class] forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:kFooterReuseIdentifier];
        [_collectionView registerClass:[CHFriendsTrayCell class] forCellWithReuseIdentifier:kFriendsCellReuseIdentifier];
    }
    return _collectionView;
}

- (CHPhotoViewSource *)photoViewSource {
    if (!_photoViewSource) {
        _photoViewSource = [[CHPhotoViewSource alloc] init];
    }
    return _photoViewSource;
}

- (CHTextViewSource *)textViewSource {
    if (!_textViewSource) {
        _textViewSource = [[CHTextViewSource alloc] init];
    }
    return _textViewSource;
}

#pragma mark - Bit picker

- (void)presentBitPicker {
    CHBitPickerViewController *bitPickerViewController = [CHBitPickerViewController sharedController];
    bitPickerViewController.delegate = self;

    CHNavigationController *navigationController = (id)self.parentViewController;
    [navigationController pushViewController:bitPickerViewController animated:YES];
}

- (void)dismissBitPicker {
    CHNavigationController *navigationController = (id)self.parentViewController;
    [navigationController popViewControllerAnimated:YES];
}

#pragma mark - UICollectionViewDataSource

- (id)bitAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == StorySectionBits) {
        if (indexPath.row < self.bits.count) {
            return [self.bits objectAtIndex:indexPath.row];
        } else {
            NSLog(@"WTF bit out of range");
        }
    }
    return nil;
}

- (NSIndexPath *)indexPathForBit:(CHBit *)bit {
    NSInteger photoIndex = [self.bits indexOfObject:bit];
    RGAssert(photoIndex != NSNotFound);
    return [NSIndexPath indexPathForItem:photoIndex inSection:StorySectionBits];
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return StorySectionCount;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    switch (section) {
        case StorySectionBits:
            return [self.bits count];
        default:
            return 1;
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                    mediaCellAtIndexPath:(NSIndexPath *)indexPath {
    
    CHPhotoBit *bit = [self bitAtIndexPath:indexPath];
    
    [self.collectionView registerClass:[CHTransformableCell class] forCellWithReuseIdentifier:bit.pk];
    CHTransformableCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:bit.pk forIndexPath:indexPath];
    
    CHFramedImageView *imageView = [self.photoViewSource viewForMediaBit:bit];
    
    if (imageView != self.draggedView) {
        [self passControlOfImageView:imageView toCell:cell animated:NO];
    }
    
    return cell;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                     textCellAtIndexPath:(NSIndexPath *)indexPath {
    
    CHTextBit *bit = [self bitAtIndexPath:indexPath];
    
    [self.collectionView registerClass:[CHTransformableCell class] forCellWithReuseIdentifier:bit.pk];
    CHTransformableCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:bit.pk forIndexPath:indexPath];
    
    if ([indexPath isEqual:self.newlyAddedIndexPath]) {
        cell.animatingIn = YES;
        
    } else {
        cell.animatingIn = NO;
        
        CHTransformableTextView *textView = [self.textViewSource viewForTextBit:bit];
        textView.delegate = self;
        
        if (textView != self.draggedView) {
            [self passControlOfTextView:textView toCell:cell animated:NO];
        }
    }
    
    return cell;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                   friendCellAtIndexPath:(NSIndexPath *)indexPath {
    
    CHFriendsTrayCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kFriendsCellReuseIdentifier forIndexPath:indexPath];
    [cell setStory:self.story];
    [cell setDelegate:self];
    return cell;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                   cellForBitAtIndexPath:(NSIndexPath *)indexPath {
    
    CHBit *bit = [self bitAtIndexPath:indexPath];
    
    switch (bit.type) {
        case CHBitTypePhoto:
        case CHBitTypeVideo:
            return [self collectionView:collectionView mediaCellAtIndexPath:indexPath];
        case CHBitTypeText:
            return [self collectionView:collectionView textCellAtIndexPath:indexPath];
        default:
            return nil;
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    switch (indexPath.section) {
        case StorySectionFriends:
            return [self collectionView:collectionView friendCellAtIndexPath:indexPath];
        case StorySectionBits:
            return [self collectionView:collectionView cellForBitAtIndexPath:indexPath];
        default:
            return nil;
    }
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView
           viewForSupplementaryElementOfKind:(NSString *)kind
                                 atIndexPath:(NSIndexPath *)indexPath {

    return [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:kFooterReuseIdentifier forIndexPath:indexPath];
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView
  didEndDisplayingCell:(UICollectionViewCell *)cell
    forItemAtIndexPath:(NSIndexPath *)indexPath {
    
    CHBit *bit = [self bitAtIndexPath:indexPath];
    if (bit.type == CHBitTypeVideo) {
        CHFramedVideoView *view = (id)[self.photoViewSource viewForMediaBit:(id)bit];
        [view pauseVideo];
    }
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGFloat)collectionView:(UICollectionView *)collectionView
                   layout:(UICollectionViewLayout *)collectionViewLayout
minimumLineSpacingForSectionAtIndex:(NSInteger)section {

    switch (section) {
        case StorySectionBits:
            return 0.0;
//            return kCellPadding;
        default:
            return 0.0;
    }
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView
                        layout:(UICollectionViewLayout *)collectionViewLayout
        insetForSectionAtIndex:(NSInteger)section {

    switch (section) {
        case StorySectionFriends:
            return UIEdgeInsetsMake(kCellPadding * 2, kCellPadding, kCellPadding * 2, kCellPadding);
        case StorySectionBits:
            return UIEdgeInsetsMake(0.0, kCellPadding, kCellPadding, kCellPadding);
        default:
            return UIEdgeInsetsZero;
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
  
    switch (indexPath.section) {
        case StorySectionFriends:
            return CGSizeMake(self.view.bounds.size.width - 2 * kCellPadding, [CHFriendsTrayCell heightWithAvatarSize:kCHAvatarSize]);
            
        case StorySectionBits: {
            NSInteger rowWidth = kRGScreenWidth - 2 * kCellPadding;
            CHBit *bit = [self bitAtIndexPath:indexPath];
            BOOL isNew = self.draggedView.attachedModel == bit && self.draggedViewIsNew;
            switch (bit.type) {
                case CHBitTypePhoto:
                case CHBitTypeVideo: {
                    CGFloat height = rowWidth / [(CHPhotoBit *)bit aspectRatio];
                    if (isNew) { height = 20.0; };
                    return CGSizeMake(rowWidth, height + kCellPadding);
                }
                case CHBitTypeText: {
                    NSString *text = [(CHTextBit *)bit text];
                    CGFloat height;
                    if ([indexPath isEqual:self.newlyAddedIndexPath]) {
                        height = self.newlyAddedIndexPathHeight;
                    } else if ([self.editingView.bit isEqual:bit]) {
                        height = self.desiredHeightForActiveTextCell + kCellPadding;
                    } else {
                        height = [CHTransformableTextView heightForText:text width:rowWidth type:[(CHTextBit *)bit textType]] + kCellPadding;
                    }
                    return CGSizeMake(rowWidth, height);
                }
                default: {
                    NSLog(@"ERROR: Unknown bit type");
                    return CGSizeZero;
                }
            }
        }

        default:
            NSAssert(NO, @"Unknown type");
            return CGSizeZero;
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
referenceSizeForFooterInSection:(NSInteger)section {

    if (section == StorySectionBits) {
        return CGSizeMake(collectionView.frameWidth, 100);
    }
    return CGSizeZero;
}

#pragma mark - RGInteractiveCollectionViewLayoutDelegate

- (void)collectionViewShouldInsertNewItemAtIndexPath:(NSIndexPath *)indexPath {
    [self setNewlyAddedIndexPath:indexPath];
    [self setNewlyAddedIndexPathHeight:0.0];
    
    CHTextBit *newBit = [CHTextBit newTextBitOfType:CHTextBitTextTypeParagraph
                                           withText:@""
                                            storyPK:self.story.pk];
    
    [CHDatabase insertBit:newBit atIndex:indexPath.item story:self.story];
    
    NSMutableArray *bits = [self.bits mutableCopy];
    [bits insertObject:newBit atIndex:indexPath.item];
    self.bits = bits;
    
    [UIView setAnimationsEnabled:NO];
    [self.collectionView insertItemsAtIndexPaths:@[indexPath]];
    [self.collectionView.collectionViewLayout invalidateLayout];
    [UIView setAnimationsEnabled:YES];
}

- (void)collectionViewShouldChangeHeightForItem:(CGFloat)height atIndexPath:(NSIndexPath *)indexPath {
    [self setNewlyAddedIndexPathHeight:height];
    
    [UIView setAnimationsEnabled:NO];
    [self.collectionView.collectionViewLayout invalidateLayout];
    [UIView setAnimationsEnabled:YES];
}

- (void)collectionViewShouldFinalizeNewItemAtIndexPath:(NSIndexPath *)indexPath velocity:(CGFloat)velocity {
    NSInteger rowWidth = kRGScreenWidth - 2 * kCellPadding;
    CGFloat targetHeight = [CHTransformableTextView heightForText:@"" width:rowWidth type:CHTextBitTextTypeParagraph] + kCellPadding;
    
    POPBasicAnimation *animation = [POPBasicAnimation animation];
    [animation setProperty:[POPAnimatableProperty propertyWithName:@"newlyAddedIndexPathHeight" initializer:^(POPMutableAnimatableProperty *prop) {
        prop.readBlock = ^(CHStoryViewController *storyVC, CGFloat values[]) {
            values[0] = self.newlyAddedIndexPathHeight;
        };
        prop.writeBlock = ^(CHStoryViewController *storyVC, const CGFloat values[]) {
            storyVC.newlyAddedIndexPathHeight = values[0];
            
            [UIView setAnimationsEnabled:NO];
            [storyVC.collectionView.collectionViewLayout invalidateLayout];
            [UIView setAnimationsEnabled:YES];
        };
        prop.threshold = 0.1;
    }]];
    animation.fromValue = @(self.newlyAddedIndexPathHeight);
    animation.toValue = @(targetHeight);
    
    animation.completionBlock = ^(POPAnimation *animationCopy, BOOL finished) {
        self.newlyAddedIndexPath = 0;
        self.newlyAddedIndexPathHeight = 0.0;
        
        CHTextBit *bit = [self bitAtIndexPath:indexPath];
        
        CHTransformableCell *cell = (id)[self.collectionView cellForItemAtIndexPath:indexPath];
        cell.animatingIn = NO;
        
        CHTransformableTextView *textView = [self.textViewSource viewForTextBit:bit];
        textView.delegate = self;
        
        if (textView != self.draggedView) {
            [self passControlOfTextView:textView toCell:cell animated:NO];
        }
        
        [textView.textField becomeFirstResponder];
    };
    
    [self pop_addAnimation:animation forKey:@"newlyAddedIndexPathHeight"];
}

- (void)collectionViewShouldDeleteItemAtIndexPath:(NSIndexPath *)indexPath velocity:(CGFloat)velocity {
    [self setNewlyAddedIndexPath:nil];
    [self setNewlyAddedIndexPathHeight:0.0];

    [self deleteBitAtIndexPath:indexPath];
}

- (void)collectionViewDidEndOrderingAtIndexPath:(NSIndexPath *)indexPath {
    CHBit *bit = [self bitAtIndexPath:indexPath];
    if ([bit isKindOfClass:[CHTextBit class]]) {
        CHTextBit *textBit = (id)bit;
        if (textBit.text.length == 0) {
            [self performInNextRunLoop:^{
                CHTransformableTextView *textView = [self.textViewSource viewForTextBit:textBit];
                [textView.textField becomeFirstResponder];
            }];
        }
    }
}

- (BOOL)interactiveCollectionView:(UICollectionView *)collectionView
                           layout:(UICollectionViewLayout *)layout
 shouldBeginReorderingAtIndexPath:(NSIndexPath *)indexPath {
    
    return indexPath.section == StorySectionBits;
}

- (BOOL)interactiveCollectionView:(UICollectionView *)collectionView
                           layout:(UICollectionViewLayout *)layout
                  itemAtIndexPath:(NSIndexPath *)fromIndexPath
            shouldMoveToIndexPath:(NSIndexPath *)toIndexPath {

    return toIndexPath.section == StorySectionBits;
}

- (void)interactiveCollectionView:(UICollectionView *)collectionView
                           layout:(UICollectionViewLayout *)layout
   willBeginReorderingAtIndexPath:(NSIndexPath *)indexPath {

    [[[UISelectionFeedbackGenerator alloc] init] selectionChanged];
    [self borderDropCellAtIndexPath:indexPath];
}

- (void)interactiveCollectionView:(UICollectionView *)collectionView
                           layout:(UICollectionViewLayout *)layout
                  itemAtIndexPath:(NSIndexPath *)fromIndexPath
              willMoveToIndexPath:(NSIndexPath *)toIndexPath {
    
    CHBit *bit = [self.bits objectAtIndex:fromIndexPath.item];
    [CHDatabase moveBit:bit
                toIndex:toIndexPath.item
                  story:self.story];
    
    NSMutableArray *bits = [self.bits mutableCopy];
    [bits removeObjectAtIndex:fromIndexPath.item];
    [bits insertObject:bit atIndex:toIndexPath.item];
    self.bits = bits;
}

- (void)interactiveCollectionView:(UICollectionView *)collectionView
                           layout:(UICollectionViewLayout *)layout
                  itemAtIndexPath:(NSIndexPath *)fromIndexPath
              didMoveToIndexPath:(NSIndexPath *)toIndexPath {

    [self borderDropCellAtIndexPath:toIndexPath];

    [[[UISelectionFeedbackGenerator alloc] init] selectionChanged];
}

- (void)interactiveCollectionView:(UICollectionView *)collectionView
                           layout:(UICollectionViewLayout *)layout
     willEndReorderingAtIndexPath:(NSIndexPath *)indexPath {
    
    [self unborderDropCell];
}

#pragma mark - Borders

- (void)borderDropCellAtIndexPath:(NSIndexPath *)indexPath {
    [self unborderDropCell];

    self.dropCell = [self.collectionView cellForItemAtIndexPath:indexPath];
    self.dropCell.contentView.backgroundColor = HEX_COLOR(0xeeeeee);
//    self.dropCell.contentView.layer.borderColor = HEX_COLOR(0xeeeeee).CGColor;
//    self.dropCell.contentView.layer.borderWidth = 2.0;
    self.dropCell.contentView.layer.cornerRadius = 6.0;
}

- (void)unborderDropCell {
    self.dropCell.contentView.backgroundColor = [UIColor whiteColor];
//    self.dropCell.contentView.layer.borderColor = [UIColor whiteColor].CGColor;
//    self.dropCell.contentView.layer.borderWidth = 0.0;
    self.dropCell.contentView.layer.cornerRadius = 0.0;
    self.dropCell = nil;
}

#pragma mark - CHKeyboardManagerDelegate

- (void)keyboardManagerKeyboardDidChangeFrame:(CHKeyboardManager *)keyboardManager {
    if (self.editingView) {
        [self updateScrollPositionForTextView:self.editingView animated:YES];
    }
}

#pragma mark - CHTransformableTextViewDelegate

- (BOOL)textViewShouldBeginEditing:(CHTransformableTextView *)textView {
    return YES;
}

- (void)textViewDidBeginEditing:(CHTransformableTextView *)textView {
    self.editingView = textView;
    
    [self updateScrollPositionForTextView:textView animated:YES];
}

- (void)textView:(CHTransformableTextView *)textView didChangeText:(NSString *)text {
    // noop otherwise soooo many db ops
}

- (void)textView:(CHTransformableTextView *)textView didChangeDesiredHeight:(CGFloat)desiredHeight {
    self.desiredHeightForActiveTextCell = desiredHeight;
    [self.collectionView.collectionViewLayout invalidateLayout];
    
    [self performInNextRunLoop:^{
        [self updateScrollPositionForTextView:textView animated:NO];
    }];
}

- (void)textView:(CHTransformableTextView *)textView didEndEditingWithText:(NSString *)text {
    self.editingView = nil;
    
    NSIndexPath *indexPath = [self indexPathForBit:textView.bit];
    
    NSString *trimmedText = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    if (trimmedText.length > 0) {
        CHTextBit *bit = self.bits[indexPath.row];
        [CHDatabase changeText:text forBit:bit];
        
    } else {
        [self deleteBitAtIndexPath:indexPath];
    }
}

- (void)updateScrollPositionForTextView:(CHTransformableTextView *)textView animated:(BOOL)animated {
    [self performInNextRunLoop:^{
        [self doUpdateScrollPositionForTextView:textView animated:animated];
    }];
}

- (void)doUpdateScrollPositionForTextView:(CHTransformableTextView *)textView animated:(BOOL)animated {
    NSIndexPath *indexPath = [self indexPathForBit:textView.bit];
    UICollectionViewLayoutAttributes *attributes = [self.layout layoutAttributesForItemAtIndexPath:indexPath];
    CGRect contentRect = CGRectInset(attributes.frame, 0.0, -kCellPadding);

    if (textView.textField.selectedRange.location == textView.textField.text.length) {
        if (self.keyboardManager.keyboardIsAnimating || animated) {
            [UIView animateWithDuration:self.keyboardManager.animationDuration delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
                [UIView setAnimationCurve:self.keyboardManager.animationCurve];
                [self.collectionView scrollRectToVisible:contentRect animated:NO];
            } completion:nil];
        } else {
            [self.collectionView scrollRectToVisible:contentRect animated:NO];
        }
    }
}

#pragma mark - CHFriendsTrayCellDelegate

- (void)friendCell:(CHFriendsTrayCell *)friendCell didTapAddFriendButtonWithExistingFriends:(NSArray *)friends {
    // TODO
}

- (void)friendCell:(CHFriendsTrayCell *)friendCell didSelectFriend:(CHPerson *)friend {
    // TODO
}

#pragma mark - CHBitPickerViewControllerDelegate

- (void)bitPickerViewController:(CHBitPickerViewController *)controller
          willBeginDraggingView:(RGTransformableView *)view
                       forPhoto:(CHPhoto *)photo {

    CHPhotoBit *bit = [CHPhotoBit newPhotoBitFromPhoto:photo storyPK:self.story.pk];
    [(CHFramedImageView *)view setPhoto:bit desiredImageSize:CHPhotoImageSizeSmall];
    [self.photoViewSource setView:(id)view forPhoto:bit];
    
    [self beginDraggingView:view forBit:bit];
}

- (void)bitPickerViewController:(CHBitPickerViewController *)controller
      willBeginDraggingTextView:(RGTransformableView *)view
                         ofType:(CHTextBitTextType)textType; {
    
    // TODO why two view sources? can we merge?
    
    CHTextBit *bit = [CHTextBit newTextBitOfType:textType
                                        withText:@""
                                         storyPK:self.story.pk];
    
    [(CHTransformableTextView *)view setBit:bit];
    [self.textViewSource setView:(id)view forTextBit:bit];
    
    [self beginDraggingView:view forBit:bit];
}

- (void)bitPickerDidDismiss:(CHBitPickerViewController *)controller {
    [self dismissBitPicker];
}

- (void)beginDraggingView:(RGTransformableView *)view
                   forBit:(CHBit *)bit {
    
    CGPoint viewPointInCollectionView = [self.collectionView convertPoint:view.center fromView:view.superview];
    CGRect viewRect = CGRectMake(0.0, viewPointInCollectionView.y, self.collectionView.frameWidth, 1.0);
    UICollectionViewLayoutAttributes *attributes = [[self.layout layoutAttributesForElementsInRect:viewRect] firstObject];
    NSInteger index = attributes.indexPath.item;
    [CHDatabase insertBit:bit atIndex:index story:self.story];
    
    NSMutableArray *bits = [self.bits mutableCopy];
    [bits insertObject:bit atIndex:index];
    self.bits = bits;
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:index inSection:StorySectionBits];
    
    self.draggedView = view;
    self.draggedViewIsNew = YES;
    view.delegate = self;
    
    [UIView setAnimationsEnabled:NO];
    [self.collectionView insertItemsAtIndexPaths:@[indexPath]];
    [self.collectionView.collectionViewLayout invalidateLayout];
    [self.collectionView layoutIfNeeded];
    [UIView setAnimationsEnabled:YES];
    
    [self.layout startDragWithView:view indexPath:indexPath];

    [self dismissBitPicker];
}

#pragma mark - Deleting bit

- (void)deleteBitAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger bitCount = self.bits.count;

    CHBit *bit = [self bitAtIndexPath:indexPath];
    [CHDatabase removeBit:bit story:self.story];

    NSMutableArray *bits = [self.bits mutableCopy];
    [bits removeObject:bit];
    self.bits = bits;

    NSAssert(self.bits.count == bitCount - 1, @"Didn't actually delete");

    [self.collectionView cellForItemAtIndexPath:indexPath].alpha = 0;

    [self.collectionView deleteItemsAtIndexPaths:@[indexPath]];
}

#pragma mark - Passing views

- (void)passControlOfGenericView:(RGTransformableView *)view
                          toCell:(CHTransformableCell *)cell
                        animated:(BOOL)animated {

    view.delegate = self;
    
    if (self.layout.draggedView != view) { // HACK
        view.desiredSize = cell.contentView.bounds.size;
    }
    [view setDesiredCenter:CGRectGetMiddle(cell.contentView.bounds) inTargetView:cell.contentView];
    [view moveToDesiredPositionAnimated:animated];
    
    [cell setTransformableView:view];
}

- (void)passControlOfImageView:(CHFramedImageView *)imageView
                        toCell:(CHTransformableCell *)cell
                      animated:(BOOL)animated {
    
    [self passControlOfGenericView:imageView toCell:cell animated:animated];
    
    [imageView setPhoto:imageView.photo desiredImageSize:CHPhotoImageSizeSmall];
}

- (void)passControlOfTextView:(CHTransformableTextView *)textView
                       toCell:(CHTransformableCell *)cell
                     animated:(BOOL)animated {
    
    [self passControlOfGenericView:textView toCell:cell animated:animated];
}

- (void)returnView:(RGTransformableView *)view animated:(BOOL)animated {
    CHBit *bit = view.attachedModel;
    NSIndexPath *indexPath = [self indexPathForBit:bit];
    UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:indexPath];
    if (cell) {
        if (bit.type == CHBitTypeText) {
            [self passControlOfTextView:(id)view toCell:(id)cell animated:animated];
        } else if (bit.type == CHBitTypePhoto) {
            [self passControlOfImageView:(id)view toCell:(id)cell animated:animated];
        }
    }
}

#pragma mark - RGTransformableViewDelegate

- (BOOL)transformableViewShouldReceieveTap:(RGTransformableView *)view {
    if ([view respondsToSelector:@selector(isEditing)]) {
        if ([(id)view isEditing]) {
            return NO;
        }
    }
    return YES;
}

- (void)transformableViewDidReceieveTap:(RGTransformableView *)view {
    CHBit *bit = view.attachedModel;
    NSIndexPath *indexPath = [self indexPathForBit:bit];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Delete?" message:@"This action cannot be undone" preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        //
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [self deleteBitAtIndexPath:indexPath];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)transformableViewDidReceieveLongPress:(RGTransformableView *)view {
    if ([view respondsToSelector:@selector(isEditing)]) {
        if ([(id)view isEditing]) {
            return;
        }
    }
    
    self.draggedView = view;
    self.draggedViewIsNew = NO;
    
    CHBit *bit = view.attachedModel;
    NSIndexPath *indexPath = [self indexPathForBit:bit];
    [self.layout startDragWithView:view indexPath:indexPath];
}

- (void)transformableViewDidTransform:(RGTransformableView *)view {
    if (view.isUserTranslating) {
        [self.layout updateDragWithView:view];
    }
}

- (void)transformableViewWillFinishUserInteraction:(RGTransformableView *)view {
    self.draggedView = nil; // important to do before layout

    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    [UIView animateWithDuration:0.2 animations:^{
        [self.layout invalidateLayout];
        [self.collectionView layoutIfNeeded];
    } completion:nil];
    
    [self returnView:view animated:YES];

    [self.layout endDragWithView:view];
}

- (BOOL)transformableViewShouldTranslateX:(RGTransformableView *)view {
    return view == self.draggedView;
}

- (BOOL)transformableViewShouldTranslateY:(RGTransformableView *)view {
    return view == self.draggedView;
}

#pragma mark - CHStoryHeaderViewDelegate

- (void)storyHeaderViewDidDismiss:(CHStoryHeaderView *)viewController {
    [self.delegate storyViewControllerDidDismiss:self];
}

#pragma mark - CHAddBitButtonDelegate

- (void)addBitButton:(CHAddBitButton *)button {
    [self presentBitPicker];
}

@end
