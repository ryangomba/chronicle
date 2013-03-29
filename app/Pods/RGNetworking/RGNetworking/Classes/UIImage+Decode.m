//  Copyright 2013-present Ryan Gomba. All rights reserved.

#import "UIImage+Decode.h"

#import <RGCore/RGAssert.h>

@implementation UINSImage (Decode)

+ (UINSImage *)decodedImageWithData:(NSData *)data {
    CGDataProviderRef dataProvider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    CGImageRef newImage = CGImageCreateWithJPEGDataProvider(dataProvider,
                                                            NULL, NO,
                                                            kCGRenderingIntentDefault);

    // force DECODE

    size_t width = CGImageGetWidth(newImage);
    size_t height = CGImageGetHeight(newImage);
    
    RGAssert(width > 0 && height > 0);
    
    unsigned char *rawData = malloc(height * width * 4);

    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(rawData, // Where to store the data. NULL = don't care
                                                 width, height, // width & height
                                                 8, width * 4, // bits per component, bytes per row
                                                 colorspace,
                                                 (CGBitmapInfo)kCGImageAlphaNoneSkipFirst);

    if (context == NULL) {
        free(rawData);
        CGColorSpaceRelease(colorspace);
        CGDataProviderRelease(dataProvider);
        CGImageRelease(newImage);
        return nil;
    }

    CGContextDrawImage(context, CGRectMake(0, 0, width, height), newImage);
    CGImageRef drawnImage = CGBitmapContextCreateImage(context);

    free(rawData);
    CGContextRelease(context);
    CGColorSpaceRelease(colorspace);

    #if TARGET_OS_IPHONE
    UIImage *image = [UIImage imageWithCGImage:drawnImage];
    #else
    NSSize imageSize = NSMakeSize(width, height);
    NSImage *image = [[NSImage alloc] initWithCGImage:drawnImage size:imageSize];
    #endif

    CGDataProviderRelease(dataProvider);
    CGImageRelease(newImage);
    CGImageRelease(drawnImage);

    return image;
}

- (NSData *)JPEGDataWithQuality:(CGFloat)quality {
    #if TARGET_OS_IPHONE
    return UIImageJPEGRepresentation(self, quality);
    #else
    NSData *rawImageData = [self TIFFRepresentation];
    NSBitmapImageRep *bitmap = [NSBitmapImageRep imageRepWithData:rawImageData];
    NSDictionary *properties = @{NSImageCompressionFactor: @(quality)};
    return [bitmap representationUsingType:NSJPEGFileType properties:properties];
    #endif
}

@end


#if !TARGET_OS_IPHONE
@implementation NSImage (UI)

- (id)initWithCGImage:(CGImageRef)CGImage {
    return [self initWithCGImage:CGImage size:NSZeroSize];
}

+ (instancetype)imageWithCGImage:(CGImageRef)CGImage {
    return [[self alloc] initWithCGImage:CGImage];
}

@end
#endif


@implementation CIImage (Initialization)

+ (instancetype)imageWithImage:(UINSImage *)image {
    #if TARGET_OS_IPHONE
    CGImageRef imageRef = image.CGImage;
    #else
    CGImageRef imageRef = [image CGImageForProposedRect:NULL context:NULL hints:nil];
    #endif
    return [self imageWithCGImage:imageRef];
}

@end

