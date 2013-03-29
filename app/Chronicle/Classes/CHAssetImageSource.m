#import "CHAssetImageSource.h"
#import <RGCore/RGCore.h>
#import <Photos/Photos.h>

@interface CHAssetImageSource ()

@property (nonatomic, strong) PHAsset *cachedAsset;
@property (nonatomic, strong) NSString *localIdentifier;
@property (nonatomic, assign) PHImageRequestID imageRequestID;
@property (nonatomic, strong) void (^sourceLoadBlock)(UIImage *image, NSData *imageData);

@end


@implementation CHAssetImageSource

#pragma mark -
#pragma mark NSObject

- (void)dealloc {
    [[PHImageManager defaultManager] cancelImageRequest:self.imageRequestID];
}

- (id)initWithLocalIdentifier:(NSString *)localIdentifier {
    if (self = [super init]) {
        self.localIdentifier = localIdentifier;
    }
    return self;
}


#pragma mark -
#pragma mark RGImageSource

- (void)loadCacheKey:(void (^)(NSString *))completion {
    [self loadAsset:^(PHAsset *asset) {
        NSString *cacheKey = [NSString stringWithFormat:@"%@-%lux%lu-%@",
                              self.localIdentifier,
                              (long)self.assetSize.width,
                              (long)self.assetSize.height,
                              asset.modificationDate];
        completion(cacheKey);
    }];
}

- (void)loadAsset:(void (^)(PHAsset *asset))completion {
    if (self.cachedAsset) {
        completion(self.cachedAsset);
    } else {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            self.cachedAsset = [PHAsset fetchAssetsWithLocalIdentifiers:@[self.localIdentifier] options:nil].firstObject;
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(self.cachedAsset);
            });
        });
    }
}

- (void)loadImage:(void (^)(UIImage *image, NSData *imageData))completion {
    self.sourceLoadBlock = [completion copy];
    
    [self loadAsset:^(PHAsset *asset) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self handleAsset:asset];
        });
    }];
}

- (void)cancel {
    // noop
}


#pragma mark -
#pragma mark Private

- (void)handleAsset:(PHAsset *)asset {
    weakify(self);
    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
    options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    
    self.imageRequestID =
    [[PHImageManager defaultManager] requestImageForAsset:asset
                                               targetSize:self.assetSize
                                              contentMode:PHImageContentModeAspectFill
                                                  options:options
                                            resultHandler:^(UIImage *result, NSDictionary *info)
     {
         strongify(self);
         dispatch_async(dispatch_get_main_queue(), ^{
             self.sourceLoadBlock(result, nil);
         });
     }];
}

@end
