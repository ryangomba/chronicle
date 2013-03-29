#import "CHPhotosLayoutManager.h"
#import <RGInterfaceKit/RGInterfaceKit.h>
#import "CHPhoto.h"
#import "CHConstants.h"

@interface CHPhotosLayoutManager ()

@property (nonatomic, strong, readwrite) UICollectionViewFlowLayout *layout;

@property (nonatomic, strong) NSArray *photoLayout;

@end


@implementation CHPhotosLayoutManager

#pragma mark -
#pragma mark NSObject

- (id)init {
    if (self = [super init]) {
        _density = CHPhotosLayoutDensityNormal;
        _shouldSquarify = YES;
        _margin = 0.0;
        _spacing = 2.5;
    }
    return self;
}


#pragma mark -
#pragma mark Properties

- (UICollectionViewFlowLayout *)layout {
    if (!_layout) {
        _layout = [[UICollectionViewFlowLayout alloc] init];
    }
    return _layout;
}

- (void)setDensity:(CHPhotosLayoutDensity)density {
    _density = density;
    
    [self setPhotoLayout:nil];
}


#pragma mark -
#pragma mark Public

- (void)invalidateLayout {
    [self setPhotoLayout:nil];
}

- (CGSize)sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (self.shouldSquarify) {
        NSInteger photosPerRow = [self maxPhotosPerRowForCurrentDensity];
        NSInteger totalMargin = 2 * self.margin;
        NSInteger totalSpacing = (photosPerRow - 1) * self.spacing;
        NSInteger size = (self.layout.collectionView.frameWidth - totalMargin - totalSpacing) / photosPerRow;
        return CGSizeMake(size, size);
        
    } else {
        NSArray *size = [self.photoLayout objectAtIndex:indexPath.row];
        return CGSizeMake([size[0] integerValue], [size[1] integerValue]);
    }
}

- (UIEdgeInsets)insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(self.margin, self.margin, 44.0, self.margin);
}

- (CGFloat)minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return self.spacing;
}

- (CGFloat)minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return self.spacing;
}


#pragma mark -
#pragma mark Photo Layout

- (NSArray *)photoLayout {
    if (!_photoLayout) {
        _photoLayout = [self sizesForPhotoGroup:self.photos];
    }
    return _photoLayout;
}

- (NSArray *)widthsForPhotoGroup:(NSArray *)photoGroup
                        rowWidth:(NSInteger)rowWidth
                  separatorWidth:(NSInteger)separatorWidth {
    
    NSInteger numBits = [photoGroup count];
    if (numBits == 0) {
        return nil;
    }
    
    NSMutableArray *groupLayout = [NSMutableArray array];
    
    CGFloat *ratios = malloc(sizeof(NSInteger) * numBits);
    CGFloat ratioSum = 0.0f;
    
    for (NSInteger i = 0; i < numBits; i++) {
        id<CHPhoto> image = [photoGroup objectAtIndex:i];
        ratios[i] = image.aspectRatio;
        ratioSum += image.aspectRatio;
    }
    
    CGFloat scale = 1.0f / ratioSum;
    CGFloat availableWidth = rowWidth - (numBits - 1) * separatorWidth;
    CGFloat additiveWidth = 0.0f;
    CGFloat height = scale * availableWidth;
    for (NSInteger i = 0; i < numBits; i++) {
        CGFloat normalizedWidth = scale * ratios[i];
        CGFloat width = floorf(availableWidth * normalizedWidth);
        if (i == numBits - 1) {
            width = availableWidth - additiveWidth;
        } else {
            additiveWidth += width;
        }
        [groupLayout addObject:@[@(width), @(height)]];
    }
    
    free(ratios);
    
    return groupLayout;
}

- (CGFloat)aspectSumForCurrentDensity {
    switch (self.density) {
        case CHPhotosLayoutDensityLinear:
            return 0.0;
        case CHPhotosLayoutDensityLoose:
            return 2.7;
        case CHPhotosLayoutDensityNormal:
            return 3.6;
        case CHPhotosLayoutDensityTight:
            return 5.0;
    }
}

- (NSInteger)maxPhotosPerRowForCurrentDensity {
    switch (self.density) {
        case CHPhotosLayoutDensityLinear:
            return 1;
        case CHPhotosLayoutDensityLoose:
            return IS_IPAD ? 4 : 3;
        case CHPhotosLayoutDensityNormal:
            return IS_IPAD ? 6 : 4;
        case CHPhotosLayoutDensityTight:
            return IS_IPAD ? 8 : 5;
    }
}

- (NSArray *)sizesForPhotoGroup:(NSArray *)photoGroup {
    NSMutableArray *photoLayout = [NSMutableArray array];
    
    NSMutableArray *workingPhotoGroup = [NSMutableArray array];
    CGFloat additiveWidth = 0.0f;
    
    NSInteger rowWidth = self.layout.collectionView.frameWidth - 2 * self.margin;
    
    for (id<CHPhoto> photo in photoGroup) {
        // TODO bad check
        CGFloat aspectSum = [self aspectSumForCurrentDensity];
        CGFloat width = photo.aspectRatio / aspectSum;
        if (additiveWidth + width > 1.0f || [workingPhotoGroup count] >= [self maxPhotosPerRowForCurrentDensity]) {
            NSArray *widths = [self widthsForPhotoGroup:workingPhotoGroup rowWidth:rowWidth separatorWidth:self.spacing];
            [photoLayout addObjectsFromArray:widths];
            
            [workingPhotoGroup removeAllObjects];
            additiveWidth = 0.0f;
        }
        [workingPhotoGroup addObject:photo];
        additiveWidth += width;
    }
    if ([workingPhotoGroup count]) {
        NSArray *widths = [self widthsForPhotoGroup:workingPhotoGroup rowWidth:rowWidth separatorWidth:self.spacing];
        [photoLayout addObjectsFromArray:widths];
    }
    
    return photoLayout;
}

@end
