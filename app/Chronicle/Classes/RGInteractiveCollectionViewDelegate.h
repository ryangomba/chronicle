#import <UIKit/UIKit.h>

@protocol RGInteractiveCollectionViewDelegate <UICollectionViewDelegateFlowLayout>

- (void)interactiveCollectionView:(UICollectionView *)collectionView
                           layout:(UICollectionViewLayout *)layout
                  itemAtIndexPath:(NSIndexPath *)fromIndexPath
              willMoveToIndexPath:(NSIndexPath *)toIndexPath;

- (void)interactiveCollectionView:(UICollectionView *)collectionView
                           layout:(UICollectionViewLayout *)layout
                  itemAtIndexPath:(NSIndexPath *)fromIndexPath
               didMoveToIndexPath:(NSIndexPath *)toIndexPath;

@optional

- (BOOL)interactiveCollectionView:(UICollectionView *)collectionView
                           layout:(UICollectionViewLayout *)layout
 shouldBeginReorderingAtIndexPath:(NSIndexPath *)indexPath;

- (BOOL)interactiveCollectionView:(UICollectionView *)collectionView
                           layout:(UICollectionViewLayout *)layout
                  itemAtIndexPath:(NSIndexPath *)fromIndexPath
            shouldMoveToIndexPath:(NSIndexPath *)toIndexPath;

- (void)interactiveCollectionView:(UICollectionView *)collectionView
                           layout:(UICollectionViewLayout *)layout
   willBeginReorderingAtIndexPath:(NSIndexPath *)indexPath;

- (void)interactiveCollectionView:(UICollectionView *)collectionView
                           layout:(UICollectionViewLayout *)layout
    didBeginReorderingAtIndexPath:(NSIndexPath *)indexPath;

- (void)interactiveCollectionView:(UICollectionView *)collectionView
                           layout:(UICollectionViewLayout *)layout
     willEndReorderingAtIndexPath:(NSIndexPath *)indexPath;

@end
