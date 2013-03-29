#import "CHThumbnailBuilder.h"
#import <QuartzCore/QuartzCore.h>
#import <RGCore/RGCore.h>
#import <RGImage/RGImage.h>
#import <RGNetworking/RGNetworking.h>
#import "RGGeometry.h"

#define kJPEGQuality 0.95

@implementation CHThumbnailBuilder

#pragma mark -
#pragma mark RGImageBuilder

- (NSString *)cacheKeyForRawImageCacheKey:(NSString *)cacheKey {
    RGAssert(!CGSizeEqualToSize(self.targetSize, CGSizeZero));
    
    NSString *sizeString = [NSString stringWithFormat:@"%lux%lu",
                            (long)self.targetSize.width,
                            (long)self.targetSize.height];
    
    return [NSString stringWithFormat:@"%@?s=%@", cacheKey, sizeString];
}

- (UIImage *)processedImageFromRawImageData:(NSData *)rawImageData
                           processedImageData:(NSData **)processedImageData {
    
    UIImage *rawImage = [[UIImage alloc] initWithData:rawImageData];
    RGAssert(rawImage);
    
    return [self processedImageFromRawImage:rawImage
                         processedImageData:processedImageData];
}

- (CGSize)resizedSizeWithImage:(UIImage *)rawImage {
    CGFloat aspectRatio = rawImage.size.width / rawImage.size.height;
    
    CGRect targetRect = CGRectMake(0.0, 0.0, self.targetSize.width, self.targetSize.height);
    CGSize outputSize = RGRectOuterRectWithAspectRatio(targetRect, aspectRatio).size;
    outputSize.width = roundf(outputSize.width);
    outputSize.height = roundf(outputSize.height);
    return outputSize;
}

- (UIImage *)processedImageFromRawImage:(UIImage *)rawImage
                       processedImageData:(NSData **)processedImageData {

    RGAssert(!CGSizeEqualToSize(self.targetSize, CGSizeZero));
    
    UIImage *finalImage = [rawImage resizedImageThatFillsBounds:[self resizedSizeWithImage:rawImage]];
    RGAssert(finalImage);
    
    NSData *imageData = [finalImage JPEGDataWithQuality:kJPEGQuality];
    RGAssert(imageData.length > 0);
    *processedImageData = imageData;
    
    return finalImage;
}

@end
