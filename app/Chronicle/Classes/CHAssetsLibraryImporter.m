#import "CHAssetsLibraryImporter.h"
#import <Photos/Photos.h>
#import <CoreLocation/CoreLocation.h>
#import "CHScreenshotIndex.h"

@interface CHAssetsLibraryImporter ()<PHPhotoLibraryChangeObserver> {
    BOOL _isImporting;
    BOOL _needsImport;
}

@end


@implementation CHAssetsLibraryImporter

#pragma mark -
#pragma mark NSObject

- (void)dealloc {
    [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
}

- (id)init {
    if (self = [super init]) {
        [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
    }
    return self;
}

+ (instancetype)sharedImporter {
    static id object;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        object = [[self alloc] init];
    });
    return object;
}

+ (CGSize)assetSizeForImageSize:(CHPhotoImageSize)desiredImageSize {
    switch (desiredImageSize) {
        case CHPhotoImageSizeUnknown:
            return CGSizeZero;
        case CHPhotoImageSizeThumbnail:
            return CGSizeMake(212.0, 212.0);
        case CHPhotoImageSizeSmall:
            return CGSizeMake(640.0, 1136.0);
    }
}


#pragma mark -
#pragma mark Public Methods

- (void)startImport {
    if (_isImporting) {
        _needsImport = YES;
        return;
    }
    
    NSLog(@"Starting library import...");

    _isImporting = YES;
    _needsImport = NO;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self doImport];
        self->_isImporting = NO;
        if (self->_needsImport) {
            [self startImport];
        }
    });
}


#pragma mark -
#pragma mark Private Methods

- (void)doImport {
    PHFetchOptions *options = [[PHFetchOptions alloc] init];
    options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES]];
    
    PHFetchResult *fetchResult = [PHAsset fetchAssetsWithOptions:options];
    
    __block NSMutableArray *allAssets = [NSMutableArray array];
    
    [fetchResult enumerateObjectsUsingBlock:^(PHAsset *asset, NSUInteger i, BOOL *stop) {
        CHPhoto *photo = [self processAsset:asset];
        [allAssets addObject:photo];
    }];
    
    self.allAssets = allAssets;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:@"assets-did-change" object:nil];
    });
}

- (CHPhoto *)processAsset:(PHAsset *)asset {
    CLLocation *location = asset.location;
    CLLocationDegrees latitude = location.coordinate.latitude;
    CLLocationDegrees longitude = location.coordinate.longitude;
    
    CGSize imageSize = CGSizeMake(asset.pixelWidth, asset.pixelHeight);
    CGFloat aspectRatio = imageSize.width / imageSize.height;
    
    BOOL isScreenshot = [CHScreenshotIndex imageSizeQualifiesAsScreenshot:imageSize];
    
    CHMediaType mediaType;
    if (isScreenshot) {
        mediaType = CHMediaTypeScreenshot;
    } else if (asset.mediaType == PHAssetMediaTypeVideo) {
        mediaType = CHMediaTypeVideo;
    } else if (asset.mediaType == PHAssetMediaTypeImage) {
        mediaType = CHMediaTypePhoto;
    } else {
        NSAssert(NO, @"Unknown media type");
        return nil;
    }
    
    CHPhoto *photo = [[CHPhoto alloc] init];
    photo.pk = asset.localIdentifier;
    photo.localIdentifier = asset.localIdentifier;
    photo.mediaType = mediaType;
    photo.creationDate = asset.creationDate;
    photo.modificationDate = asset.modificationDate;
    photo.aspectRatio = aspectRatio;
    photo.latitude = latitude;
    photo.longitude = longitude;
    photo.isFavorite = asset.isFavorite;
    return photo;
}


#pragma mark -
#pragma mark PHPhotoLibraryChangeObserver

- (void)photoLibraryDidChange:(PHChange *)changeInstance {
    [self startImport];
}

@end
