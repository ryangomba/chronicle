#import "RGInteractiveCollectionViewDelegate.h"
#import "RGTransformableView.h"

// HACK
@protocol RGInteractiveCollectionViewLayoutDelegate <NSObject>

- (void)collectionViewShouldInsertNewItemAtIndexPath:(NSIndexPath *)indexPath;
- (void)collectionViewShouldChangeHeightForItem:(CGFloat)height atIndexPath:(NSIndexPath *)indexPath;
- (void)collectionViewShouldFinalizeNewItemAtIndexPath:(NSIndexPath *)indexPath velocity:(CGFloat)velocity;
- (void)collectionViewShouldDeleteItemAtIndexPath:(NSIndexPath *)indexPath velocity:(CGFloat)velocity;
- (void)collectionViewDidEndOrderingAtIndexPath:(NSIndexPath *)indexPath;

@end

@interface RGInteractiveCollectionViewLayout : UICollectionViewFlowLayout <UIGestureRecognizerDelegate>

@property (nonatomic, strong, readonly) RGTransformableView *draggedView;

@property (nonatomic, weak) id<RGInteractiveCollectionViewLayoutDelegate> specialLayoutDelegate;

- (void)startDragWithView:(RGTransformableView *)view indexPath:(NSIndexPath *)indexPath;
- (void)updateDragWithView:(RGTransformableView *)view;
- (void)endDragWithView:(RGTransformableView *)view;

- (void)scaleDownWithCompletion:(void(^)(void))completion;
- (void)scaleUpWithCompletion:(void(^)(void))completion;

@end
