#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, CHPhotosLayoutDensity) {
    CHPhotosLayoutDensityLinear,
    CHPhotosLayoutDensityLoose,
    CHPhotosLayoutDensityNormal,
    CHPhotosLayoutDensityTight,
};

@interface CHPhotosLayoutManager : NSObject

@property (nonatomic, assign) CGFloat margin;
@property (nonatomic, assign) CGFloat spacing;
@property (nonatomic, assign) CHPhotosLayoutDensity density;
@property (nonatomic, assign) BOOL shouldSquarify;

@property (nonatomic, strong) NSArray *photos;

@property (nonatomic, strong, readonly) UICollectionViewFlowLayout *layout;

- (void)invalidateLayout;

- (CGSize)sizeForItemAtIndexPath:(NSIndexPath *)indexPath;
- (UIEdgeInsets)insetForSectionAtIndex:(NSInteger)section;
- (CGFloat)minimumLineSpacingForSectionAtIndex:(NSInteger)section;
- (CGFloat)minimumInteritemSpacingForSectionAtIndex:(NSInteger)section;

@end
