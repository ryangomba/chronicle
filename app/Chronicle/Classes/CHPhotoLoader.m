#import "CHPhotoLoader.h"

#import "CHAssetsLibraryImporter.h"
#import "CHAssetImageSource.h"

@implementation CHPhotoLoader

+ (id<RGImageSource>)sourceForPhoto:(id<CHPhoto>)photo imageSize:(CHPhotoImageSize)imageSize {
    CHAssetImageSource *source = [[CHAssetImageSource alloc] initWithLocalIdentifier:photo.localIdentifier];
    [source setAssetSize:[CHAssetsLibraryImporter assetSizeForImageSize:imageSize]];
    return source;
}

@end
