#import "RGInteractiveCollectionViewLayout.h"

#import "RGGeometry.h"
#import "CHFramedImageView.h"
#import <pop/POP.h>
#import <pop/POPLayerExtras.h>

#define kFPS 60.0
#define kCollectionViewScaleFactor 0.6
#define kDefaultInset 120.0
#define kDefaultScrollingSpeed 600.0
#define kTopBottomExtraInsets 200.0

typedef NS_ENUM(NSInteger, ScrollingDirection) {
    ScrollingDirectionUp = 1,
    ScrollingDirectionDown,
};

typedef NS_ENUM(NSInteger, ScaleState) {
    ScaleStateScaledUp,
    ScaleStateScalingUp,
    ScaleStateScaledDown,
    ScaleStateScalingDown,
};

static NSString * const kScrollingDirectionKey = @"scrollingDirection";

@interface RGInteractiveCollectionViewLayout () {
    ScaleState _scaleState;
}

@property (nonatomic, assign) UIEdgeInsets triggerScrollingEdgeInsets;
@property (nonatomic, assign) CGFloat scrollingSpeed;
@property (nonatomic, strong) NSTimer *scrollingTimer;

@property (nonatomic, strong) UIPinchGestureRecognizer *pinchGestureRecognizer;

@property (nonatomic, strong, readwrite) RGTransformableView *draggedView;
@property (nonatomic, strong) NSIndexPath *draggedItemIndexPath;

@property (nonatomic, assign) CGPoint fingerCenter;
@property (nonatomic, assign) CGPoint targetCenter;

@property (nonatomic, readonly) id delegate;

@end

@implementation RGInteractiveCollectionViewLayout

- (instancetype)init {
    if (self = [super init]) {
        self.triggerScrollingEdgeInsets = UIEdgeInsetsMake(kDefaultInset, kDefaultInset, kDefaultInset, kDefaultInset);
        self.scrollingSpeed = kDefaultScrollingSpeed;

        self.pinchGestureRecognizer = [[UIPinchGestureRecognizer alloc] init];
        [self.pinchGestureRecognizer addTarget:self action:@selector(onPinch:)];
        [self.pinchGestureRecognizer setDelegate:self];
    }
    return self;
}

- (id)delegate {
    return self.collectionView.delegate;
}

- (UIView *)containerView {
    return self.collectionView.superview;
}

#pragma mark - Layout

- (void)prepareLayout {
    [super prepareLayout];

    [self.collectionView addGestureRecognizer:self.pinchGestureRecognizer];
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect {
    NSArray *layoutAttributesForElementsInRect = [super layoutAttributesForElementsInRect:rect];

    for (UICollectionViewLayoutAttributes *layoutAttributes in layoutAttributesForElementsInRect) {
        switch (layoutAttributes.representedElementCategory) {
            case UICollectionElementCategoryCell:
                [self applyLayoutAttributes:layoutAttributes];
                break;
            default:
                break;
        }
    }

    return layoutAttributesForElementsInRect;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewLayoutAttributes *attributes = [super layoutAttributesForItemAtIndexPath:indexPath];

    switch (attributes.representedElementCategory) {
        case UICollectionElementCategoryCell:
            [self applyLayoutAttributes:attributes];
            break;
        default:
            break;
    }

    return attributes;
}

- (void)applyLayoutAttributes:(UICollectionViewLayoutAttributes *)layoutAttributes {
    if ([layoutAttributes.indexPath isEqual:self.draggedItemIndexPath]) {
        layoutAttributes.zIndex = -1; // go behind (but doesn't seem to work)
    } else {
        layoutAttributes.zIndex = 0;
    }
}

#pragma mark - Reordering

- (void)reorderIfNecessary {
    NSIndexPath *previousDraggedItemIndexPath = self.draggedItemIndexPath;
    if (!previousDraggedItemIndexPath) {
        return;
    }

    CGPoint collectionViewPoint = [self.draggedView.superview convertPoint:self.draggedView.center toView:self.collectionView];

    CGFloat mandatoryInset = 1.0;
    collectionViewPoint.x = MIN(collectionViewPoint.x, self.collectionView.contentSize.width - mandatoryInset);
    collectionViewPoint.y = MIN(collectionViewPoint.y, self.collectionView.contentSize.height - mandatoryInset);
    collectionViewPoint.x = MAX(collectionViewPoint.x, mandatoryInset);
    collectionViewPoint.y = MAX(collectionViewPoint.y, mandatoryInset);
    
    CGRect hoverRect = CGRectMake(0.0, collectionViewPoint.y, self.collectionView.bounds.size.width, 1.0);
    UICollectionViewLayoutAttributes *attributes = [[self layoutAttributesForElementsInRect:hoverRect] firstObject];
    NSIndexPath *draggedItemIndexPath = attributes.indexPath;

    if (attributes.representedElementKind == UICollectionElementKindSectionFooter) {
        // HACK footer
        NSInteger numberOfItemsInSection = [self.collectionView.dataSource collectionView:self.collectionView numberOfItemsInSection:self.draggedItemIndexPath.section];
        draggedItemIndexPath = [NSIndexPath indexPathForRow:numberOfItemsInSection-1 inSection:self.draggedItemIndexPath.section];
    }

    if (!draggedItemIndexPath) {
        return;
    }

    switch ([draggedItemIndexPath compare:previousDraggedItemIndexPath]) {
        case NSOrderedAscending:
            // new IP is above; require center to be above IP center
            if (collectionViewPoint.y >= attributes.center.y) {
                return;
            }
            break;
            
        case NSOrderedDescending:
            // new IP is below; require center to be below IP center
            if (collectionViewPoint.y <= attributes.center.y) {
                return;
            }
            break;
            
        default:
            return;
    }
        
    // check with the delegate to see if this move is even allowed.
    
    if ([self.delegate respondsToSelector:@selector(interactiveCollectionView:layout:itemAtIndexPath:shouldMoveToIndexPath:)]) {
        BOOL shouldMove = [self.delegate interactiveCollectionView:self.collectionView
                                                            layout:self
                                                   itemAtIndexPath:previousDraggedItemIndexPath
                                             shouldMoveToIndexPath:draggedItemIndexPath];
        
        if (!shouldMove) {
            return;
        }
    }
    
    self.draggedItemIndexPath = draggedItemIndexPath;
    
    // Proceed with the move
    
    [self.delegate interactiveCollectionView:self.collectionView
                                      layout:self
                             itemAtIndexPath:previousDraggedItemIndexPath
                         willMoveToIndexPath:draggedItemIndexPath];
    
    [self.collectionView performBatchUpdates:^{
        [self.collectionView moveItemAtIndexPath:previousDraggedItemIndexPath toIndexPath:draggedItemIndexPath];
    } completion:nil];
    
    UICollectionViewCell *newCell = [self.collectionView cellForItemAtIndexPath:draggedItemIndexPath];
    [self.draggedView setDesiredCenter:self.draggedView.desiredCenter inTargetView:newCell.contentView];
    
    [self.delegate interactiveCollectionView:self.collectionView
                                      layout:self
                             itemAtIndexPath:previousDraggedItemIndexPath
                          didMoveToIndexPath:draggedItemIndexPath];
}

#pragma mark - Scaling up and down

- (void)scaleDownWithCompletion:(void(^)(void))completion {
    if (_scaleState == ScaleStateScaledDown) {
        return;
    }

    [self.collectionView setContentInset:UIEdgeInsetsMake(400, 0, 400, 0)];
    CGRect collectionViewBounds = self.collectionView.bounds;
    CGFloat oldHeight = collectionViewBounds.size.height;
    CGFloat newHeight = oldHeight / kCollectionViewScaleFactor;
    collectionViewBounds.size.height = newHeight;
    [self.collectionView setBounds:collectionViewBounds];

    _scaleState = ScaleStateScalingDown;
    [self scaleToScaleFactor:kCollectionViewScaleFactor completion:^{
        [self adjustContentOffsetForPercentComplete:1.0];
        self->_scaleState = ScaleStateScaledDown;
        if (completion) {
            completion();
        }
    }];
}

- (void)scaleUpWithCompletion:(void(^)(void))completion {
    if (_scaleState == ScaleStateScaledUp) {
        return;
    }

    _scaleState = ScaleStateScalingUp;
    [self scaleToScaleFactor:1.0 completion:^{
        [self.collectionView setBounds:self.containerView.bounds];
        [self.collectionView setContentInset:UIEdgeInsetsMake(0, 0, 0, 0)];

        [self adjustContentOffsetForPercentComplete:1.0];
        self->_scaleState = ScaleStateScaledUp;
        if (completion) {
            completion();
        }
    }];
}

- (void)scaleToScaleFactor:(CGFloat)scaleFactor completion:(void(^)(void))completion {
    POPSpringAnimation *ts = [POPSpringAnimation animation];
    ts.springBounciness = 0.0;
    ts.springSpeed = 20.0;
    ts.property = [POPAnimatableProperty propertyWithName:kPOPLayerScaleXY];
    ts.fromValue = [NSValue valueWithCGPoint:POPLayerGetScaleXY(self.collectionView.layer)];
    ts.toValue = [NSValue valueWithCGPoint:CGPointMake(scaleFactor, scaleFactor)];
    ts.animationDidApplyBlock = ^(POPAnimation *anim) {
        CGFloat fromY = [((POPBasicAnimation *)anim).fromValue CGPointValue].y;
        CGFloat toY = [((POPBasicAnimation *)anim).toValue CGPointValue].y;
        CGFloat currentY = POPLayerGetScaleXY(self.collectionView.layer).y;
        CGFloat percentComplete = (currentY - fromY) / (toY - fromY);
        [self adjustContentOffsetForPercentComplete:percentComplete];
    };
    ts.completionBlock = ^(POPAnimation *animation, BOOL finished) {
        if (finished) {
            if (completion) {
                completion();
            }
        }
    };
    [self.collectionView.layer pop_addAnimation:ts forKey:kPOPLayerScaleXY];
}

- (void)adjustContentOffsetForPercentComplete:(CGFloat)percentComplete {
    CGFloat centerY = self.fingerCenter.y + (self.targetCenter.y - self.fingerCenter.y) * percentComplete;
    CGPoint fingerPointInContainerView = CGPointMake(self.fingerCenter.x, centerY);
    CGPoint fingerPointInCollectionView = [self.collectionView convertPoint:fingerPointInContainerView fromView:self.containerView];
    CGPoint cellCenterInCollectionView = [self layoutAttributesForItemAtIndexPath:self.draggedItemIndexPath].center;
    CGPoint newContentOffset = self.collectionView.contentOffset;
    newContentOffset.y += (cellCenterInCollectionView.y - fingerPointInCollectionView.y);
    [self.collectionView setContentOffset:newContentOffset animated:NO];
}

#pragma mark - Dragging

- (void)startDragWithView:(RGTransformableView *)view indexPath:(NSIndexPath *)indexPath {
    self.draggedView = view;
    
    self.fingerCenter = [view.superview convertPoint:view.center toView:self.containerView];
    self.targetCenter = self.fingerCenter;
    
    // TODO
    self.collectionView.panGestureRecognizer.enabled = NO;
    self.collectionView.panGestureRecognizer.enabled = YES;
    
    dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.0 * NSEC_PER_SEC));
    dispatch_after(delay, dispatch_get_main_queue(), ^{
        [self onLongPressStartWithIndexPath:indexPath];
    });
}

- (void)onLongPressStartWithIndexPath:(NSIndexPath *)draggedItemIndexPath {
    self.draggedItemIndexPath = draggedItemIndexPath;

    CGFloat collapsedWidth = self.collectionView.bounds.size.width * kCollectionViewScaleFactor;

    BOOL isNew = self.draggedView.bounds.size.width < collapsedWidth; // HACK

    // downscale image?
    if (!isNew) {
        CGFloat currentAspectRatio = self.draggedView.bounds.size.width / self.draggedView.bounds.size.height;
        CGFloat aspectRatio = self.draggedView.aspectRatio ?: currentAspectRatio;
        NSInteger collapsedHeight = collapsedWidth / aspectRatio;
        CGSize collapsedSize = CGSizeMake(collapsedWidth, collapsedHeight);
        [self.draggedView setDesiredSize:collapsedSize];
    }
    [self.draggedView moveToDesiredPositionAnimated:YES];

    if ([self.delegate respondsToSelector:@selector(interactiveCollectionView:layout:shouldBeginReorderingAtIndexPath:)]) {
        BOOL shouldStartReorder =  [self.delegate interactiveCollectionView:self.collectionView layout:self shouldBeginReorderingAtIndexPath:draggedItemIndexPath];
        if (!shouldStartReorder) {
            return;
        }
    }

    if ([self.delegate respondsToSelector:@selector(interactiveCollectionView:layout:willBeginReorderingAtIndexPath:)]) {
        [self.delegate interactiveCollectionView:self.collectionView layout:self willBeginReorderingAtIndexPath:draggedItemIndexPath];
    }

    [self scaleDownWithCompletion:^{
        if ([self.delegate respondsToSelector:@selector(interactiveCollectionView:layout:didBeginReorderingAtIndexPath:)]) {
            [self.delegate interactiveCollectionView:self.collectionView layout:self didBeginReorderingAtIndexPath:draggedItemIndexPath];
        }
    }];
}

- (void)updateDragWithView:(RGTransformableView *)view {
    if (!view.isUserTranslating) {
        return;
    }
    if (_scaleState == ScaleStateScalingUp || _scaleState == ScaleStateScalingDown) {
        return;
    }

    CGPoint locationInContainerView = [self.containerView convertPoint:self.draggedView.center fromView:self.draggedView.superview];

    [self reorderIfNecessary];

    if (locationInContainerView.y < (CGRectGetMinY(self.containerView.bounds) + self.triggerScrollingEdgeInsets.top)) {
        BOOL isScrollingTimerSetUpNeeded = YES;
        if (self.scrollingTimer) {
            if (self.scrollingTimer.isValid) {
                isScrollingTimerSetUpNeeded = ([self.scrollingTimer.userInfo[kScrollingDirectionKey] integerValue] != ScrollingDirectionUp);
            }
        }
        if (isScrollingTimerSetUpNeeded) {
            if (self.scrollingTimer) {
                [self.scrollingTimer invalidate];
                self.scrollingTimer = nil;
            }
            self.scrollingTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 / kFPS
                                                                   target:self
                                                                 selector:@selector(handleScroll:)
                                                                 userInfo:@{ kScrollingDirectionKey : @( ScrollingDirectionUp ) }
                                                                  repeats:YES];
        }

    } else if (locationInContainerView.y > (CGRectGetMaxY(self.containerView.bounds) - self.triggerScrollingEdgeInsets.bottom)) {
        BOOL isScrollingTimerSetUpNeeded = YES;
        if (self.scrollingTimer) {
            if (self.scrollingTimer.isValid) {
                isScrollingTimerSetUpNeeded = ([self.scrollingTimer.userInfo[kScrollingDirectionKey] integerValue] != ScrollingDirectionDown);
            }
        }
        if (isScrollingTimerSetUpNeeded) {
            if (self.scrollingTimer) {
                [self.scrollingTimer invalidate];
                self.scrollingTimer = nil;
            }
            self.scrollingTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 / kFPS
                                                                   target:self
                                                                 selector:@selector(handleScroll:)
                                                                 userInfo:@{ kScrollingDirectionKey : @( ScrollingDirectionDown ) }
                                                                  repeats:YES];
        }

    } else {
        if (self.scrollingTimer) {
            [self.scrollingTimer invalidate];
            self.scrollingTimer = nil;
        }
    }
}

- (void)endDragWithView:(RGTransformableView *)view {
    CGPoint cellCenterInCollectionView = [self layoutAttributesForItemAtIndexPath:self.draggedItemIndexPath].center;
    self.fingerCenter = [self.collectionView convertPoint:cellCenterInCollectionView toView:self.containerView];
    
    CGPoint desiredTargetCenter = CGRectGetMiddle(self.containerView.bounds);
    
    // if the desired center is higher than the cell's natural position in the collection view, clamp
    CGFloat cellCenterDistanceFromBottom = self.collectionView.contentSize.height - cellCenterInCollectionView.y;
    CGFloat cellCenterInContainerView = self.containerView.bounds.size.height - cellCenterDistanceFromBottom;
    desiredTargetCenter.y = MAX(cellCenterInContainerView, desiredTargetCenter.y);
    
    // if the desired center is lower than the cell's natural position in the collection view, clamp
    desiredTargetCenter.y = MIN(cellCenterInCollectionView.y, desiredTargetCenter.y);
    
    self.targetCenter = desiredTargetCenter;
    
    dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.0 * NSEC_PER_SEC));
    dispatch_after(delay, dispatch_get_main_queue(), ^{
        [self onLongPressEnd];
    });
}

- (void)onLongPressEnd {
    NSIndexPath *draggedItemIndexPath = self.draggedItemIndexPath;
    
    if ([self.delegate respondsToSelector:@selector(interactiveCollectionView:layout:willEndReorderingAtIndexPath:)]) {
        [self.delegate interactiveCollectionView:self.collectionView layout:self willEndReorderingAtIndexPath:draggedItemIndexPath];
    }

    [self.scrollingTimer invalidate];
    [self setScrollingTimer:nil];

    CGSize fullSize = self.draggedView.targetView.bounds.size;
    CGSize newSize = CGSizeMake(fullSize.width, fullSize.height);
    [self.draggedView setDesiredSize:newSize];
    [self.draggedView moveToDesiredPositionAnimated:YES];
 
    // TODO need to fix this; scaling should "just work" if target view changes its own scale
    dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.65 * NSEC_PER_SEC));
    dispatch_after(delay, dispatch_get_main_queue(), ^{
        [self scaleUpWithCompletion:^{
            [self.delegate collectionViewDidEndOrderingAtIndexPath:self.draggedItemIndexPath];
            self.draggedItemIndexPath = nil;
            self.draggedView = nil;
        }];
    });
}

#pragma mark - Pinching

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if ([gestureRecognizer isEqual:self.pinchGestureRecognizer]) {
        if ([RGTransformableView isActive]) {
            return NO;
        }
        CGPoint touch0 = [self.pinchGestureRecognizer locationOfTouch:0 inView:self.collectionView];
        CGPoint touch1 = [self.pinchGestureRecognizer locationOfTouch:1 inView:self.collectionView];
        NSIndexPath *indexPath0 = [self.collectionView indexPathForItemAtPoint:touch0];
        NSIndexPath *indexPath1 = [self.collectionView indexPathForItemAtPoint:touch1];
        return ABS(indexPath0.item - indexPath1.item) == 1;
    }
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    if ([gestureRecognizer isEqual:self.pinchGestureRecognizer]) {
        if ([otherGestureRecognizer isEqual:self.collectionView.panGestureRecognizer]) {
            return YES;
        }
    }

    return NO;
}

- (void)onPinch:(UIPinchGestureRecognizer *)recognizer {
    static NSInteger topTouchIndex;
    static NSInteger bottomTouchIndex;
    static CGFloat topTouchStartY;
    static CGFloat bottomTouchStartY;
    static CGFloat contentOffsetStartY;
    static NSIndexPath *newIndexPath;

    switch (recognizer.state) {
        case UIGestureRecognizerStateBegan: {
            if (recognizer.numberOfTouches == 2) {
                CGFloat touch0Y = [recognizer locationOfTouch:0 inView:self.collectionView.superview].y;
                CGFloat touch1Y = [recognizer locationOfTouch:1 inView:self.collectionView.superview].y;
                BOOL touch0IsTop = touch0Y < touch1Y;
                topTouchIndex = touch0IsTop ? 0 : 1;
                bottomTouchIndex = touch0IsTop ? 1 : 0;
                topTouchStartY = touch0IsTop ? touch0Y : touch1Y;
                bottomTouchStartY = touch0IsTop ? touch1Y : touch0Y;

                contentOffsetStartY = self.collectionView.contentOffset.y;

                CGPoint pointInCollectionView = [recognizer locationOfTouch:bottomTouchIndex inView:self.collectionView];
                newIndexPath = [self.collectionView indexPathForItemAtPoint:pointInCollectionView];
                [self.specialLayoutDelegate collectionViewShouldInsertNewItemAtIndexPath:newIndexPath];
            }
        };

        case UIGestureRecognizerStateChanged: {
            if (recognizer.numberOfTouches == 2) {
                CGFloat fullSize = 40; // HACK
                CGFloat topTouchY = [recognizer locationOfTouch:topTouchIndex inView:self.collectionView.superview].y;
                CGFloat bottomTouchY = [recognizer locationOfTouch:bottomTouchIndex inView:self.collectionView.superview].y;
                CGFloat topDelta = MAX(topTouchStartY - topTouchY, 0.0);
                CGFloat bottomDelta = MAX(bottomTouchY - bottomTouchStartY, 0.0);
                CGFloat fullDelta = topDelta + bottomDelta;

                CGFloat newIndexPathHeight = MIN(fullDelta, fullSize) + powf(MAX(fullDelta - fullSize, 0), 0.7);

                CGFloat newContentOffsetY = contentOffsetStartY + newIndexPathHeight / 2;
                [self.collectionView setContentOffset:CGPointMake(0, newContentOffsetY)];

                [self.specialLayoutDelegate collectionViewShouldChangeHeightForItem:newIndexPathHeight atIndexPath:newIndexPath];
            }
        } break;

        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled: {
            if (recognizer.velocity > 0) {
                [self.specialLayoutDelegate collectionViewShouldFinalizeNewItemAtIndexPath:newIndexPath velocity:recognizer.velocity];
            } else {
                [self.specialLayoutDelegate collectionViewShouldDeleteItemAtIndexPath:newIndexPath velocity:recognizer.velocity];
            }
        } break;

        default:
            break;
    }
}

#pragma mark - Edge scroll

- (void)handleScroll:(NSTimer *)timer {
    ScrollingDirection scrollingDirection = (ScrollingDirection)[timer.userInfo[kScrollingDirectionKey] integerValue];

    switch (scrollingDirection) {
        case ScrollingDirectionUp: {
            CGFloat distance = -(self.scrollingSpeed / kFPS);
            CGPoint contentOffset = self.collectionView.contentOffset;
            CGFloat normalMinY = -kTopBottomExtraInsets;
            CGFloat minY = MIN(self.collectionView.contentOffset.y, normalMinY);
            if ((contentOffset.y + distance) <= minY) {
                distance = 0.0;
            }
            self.collectionView.contentOffset = CGPointOffsetY(contentOffset, distance);
        } break;

        case ScrollingDirectionDown: {
            CGFloat distance = (self.scrollingSpeed / kFPS);
            CGPoint contentOffset = self.collectionView.contentOffset;
            CGFloat normalMaxY = MAX(self.collectionView.contentSize.height, CGRectGetHeight(self.collectionView.bounds)) - CGRectGetHeight(self.collectionView.bounds) + kTopBottomExtraInsets;
            CGFloat maxY = MAX(self.collectionView.contentOffset.y, normalMaxY);
            if ((contentOffset.y + distance) >= maxY) {
                distance = 0.0;
            }
            self.collectionView.contentOffset = CGPointOffsetY(contentOffset, distance);
        } break;

        default:
            break;
    }

    [self reorderIfNecessary];
}

@end
