#import "CHPhotoView.h"

#import "CHImageLoader.h"
#import "CHAssetImageSource.h"
#import "CHAssetsLibraryImporter.h"
#import "CHPhotoLoader.h"
#import "CHThumbnailBuilder.h"
#import <RGCore/RGCore.h>

@interface CHPhotoView ()

@property (nonatomic, strong) CHImageLoader *imageLoader;

@end


@implementation CHPhotoView

#pragma mark -
#pragma mark NSObject

- (void)dealloc {
    [self.imageLoader cancel];
}


#pragma mark -
#pragma mark Public

- (void)setPhoto:(id<CHPhoto>)photo desiredImageSize:(CHPhotoImageSize)desiredImageSize {
    BOOL newPhoto = photo != _photo;
    BOOL newSize = desiredImageSize != _desiredImageSize;
    
    if (!newPhoto && !newSize) {
        return;
    }
    
    _photo = photo;
    _desiredImageSize = desiredImageSize;
    
//    if (newPhoto) {
//        [self setImage:nil];
//    }
    
    [self loadImage];
}


#pragma mark -
#pragma mark Private

- (void)loadImage {
    if (!self.photo || self.desiredImageSize == CHPhotoImageSizeUnknown) {
        [self setImage:nil];
        return;
    }
    
    [self.imageLoader cancel];
    
    id<RGImageSource> imageSource = [CHPhotoLoader sourceForPhoto:self.photo imageSize:self.desiredImageSize];
    CHImageLoader *newImageLoader = [[CHImageLoader alloc] initWithImageSource:imageSource];
    
    CHThumbnailBuilder *thumbnailBuilder = [[CHThumbnailBuilder alloc] init];
    
    CGSize targetSize = [CHAssetsLibraryImporter assetSizeForImageSize:self.desiredImageSize];
    [thumbnailBuilder setTargetSize:targetSize];
    
    [newImageLoader setImageBuilder:thumbnailBuilder];
    
    [self setImageLoader:newImageLoader];
    
    weakify(self);
    [self.imageLoader loadImage:^(UIImage *image) {
        strongify(self);
        [self setImage:image];
    }];
}

@end
