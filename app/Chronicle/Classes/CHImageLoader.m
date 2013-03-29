#import "CHImageLoader.h"
#import <RGCore/RGCore.h>
#import <RGNetworking/RGNetworking.h>

@interface CHImageLoader ()

@property (nonatomic, strong) id<RGImageSource> imageSource;
@property (nonatomic, copy) void (^completionBlock)(UIImage *image);

@end


@implementation CHImageLoader

#pragma mark -
#pragma mark NSObject

- (void)dealloc {
    [self cancel];
}

- (id)initWithImageSource:(id<RGImageSource>)imageSource {
    if (self = [super init]) {
        self.imageSource = imageSource;
    }
    return self;
}


#pragma mark -
#pragma mark Public

- (void)loadImage:(void (^)(UIImage *image))completion {
    [self setCompletionBlock:completion];
    
    // is the image in the decoded image cache?
    
    [self loadFinalImageCacheKey:^(NSString *finalImageCacheKey) {
        UIImage *decodedImage = [[RGDecodedImageCache sharedCache] imageForKey:finalImageCacheKey];
        if (decodedImage) {
            [self executeCompletionBlockWithImage:decodedImage];
            return;
        }
        
        // is the image in the disk cache?
        
        [[RGCache sharedCache] objectForKey:finalImageCacheKey completion:^(NSData *cachedImageData) {
            if (cachedImageData) {
                weakify(self);
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    strongify(self);
                    UIImage *image = [UIImage decodedImageWithData:cachedImageData];
                    [[RGDecodedImageCache sharedCache] setImage:image forKey:finalImageCacheKey];
                    [self executeCompletionBlockWithImage:image];
                });
                
            } else {
                [self.imageSource loadImage:^(UIImage *image, NSData *imageData) {
                    if (image || imageData) {
                        weakify(self);
                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                            strongify(self);
                            [self handleSourceImage:image imageData:imageData];
                        });
                    } else {
                        [self executeCompletionBlockWithImage:nil];
                    }
                }];
            }
        }];
    }];
}


#pragma mark -
#pragma mark Private

- (void)loadFinalImageCacheKey:(void (^)(NSString *finalImageCacheKey))completion {
    [self.imageSource loadCacheKey:^(NSString *cacheKey) {
        if (self.imageBuilder) {
            completion([self.imageBuilder cacheKeyForRawImageCacheKey:cacheKey]);
        }
        completion(cacheKey);
    }];
}

- (void)handleSourceImage:(UIImage *)sourceImage imageData:(NSData *)sourceImageData {
    UIImage *finalImage = nil;
    NSData *finalImageData = nil;
    
    if (self.imageBuilder) {
        if (sourceImage) {
            finalImage = [self.imageBuilder processedImageFromRawImage:sourceImage
                                                    processedImageData:&finalImageData];
        } else {
            finalImage = [self.imageBuilder processedImageFromRawImageData:sourceImageData
                                                        processedImageData:&finalImageData];
        }
        
    } else {
        finalImage = sourceImage ?: [UIImage decodedImageWithData:sourceImageData];
        finalImageData = sourceImageData ?: [sourceImage JPEGDataWithQuality:0.95];
    }
    
    [self loadFinalImageCacheKey:^(NSString *finalImageCacheKey) {
        [[RGCache sharedCache] setObject:finalImageData forKey:finalImageCacheKey];
        [[RGDecodedImageCache sharedCache] setImage:finalImage forKey:finalImageCacheKey];
        
        [self executeCompletionBlockWithImage:finalImage];
    }];
}

- (void)executeCompletionBlockWithImage:(UIImage *)image {
    weakify(self);
    dispatch_async(dispatch_get_main_queue(), ^{
        strongify(self);
        if (self.completionBlock) {
            self.completionBlock(image);
        }
    });
}

- (void)cancel {
    [self setCompletionBlock:nil];
    [self.imageSource cancel];
}

@end
