#import <UIKit/UIKit.h>

@protocol RGImageSource <NSObject>

- (void)loadCacheKey:(void (^)(NSString *cacheKey))completion;
- (void)loadImage:(void (^)(UIImage *image, NSData *imageData))completion;
- (void)cancel;

@end

@protocol RGImageBuilder <NSObject>

- (NSString *)cacheKeyForRawImageCacheKey:(NSString *)cacheKey;

- (UIImage *)processedImageFromRawImage:(UIImage *)rawImage
                       processedImageData:(NSData **)processedImageData;

- (UIImage *)processedImageFromRawImageData:(NSData *)rawImageData
                           processedImageData:(NSData **)processedImageData;

@end

@interface CHImageLoader : NSObject

@property (nonatomic, strong) id<RGImageBuilder> imageBuilder;

- (id)initWithImageSource:(id<RGImageSource>)imageSource;

- (void)loadImage:(void (^)(UIImage *image))completion;
- (void)cancel;

@end
