// Copyright 2014-present Ryan Gomba. All Rights Reserved.

#import "UIImage+Resize.h"

@implementation UIImage (Resize)

#pragma mark -
#pragma mark Public Methods

- (CGImageRef)newCGImageWithCropRect:(CGRect)cropRect {
    CGRect finalCropRect = [self cropRectForOrientation:cropRect];
    CGImageRef croppedImage = CGImageCreateWithImageInRect(self.CGImage, finalCropRect);
    return croppedImage;
}

- (UIImage *)croppedImage:(CGRect)cropRect {
    CGImageRef croppedImageRef = [self newCGImageWithCropRect:cropRect];
    UIImage *croppedImage = [UIImage imageWithCGImage:croppedImageRef scale:1.0f orientation:self.imageOrientation];
    CGImageRelease(croppedImageRef);
    return croppedImage;
}

- (UIImage *)squareThumbnailImageOfSize:(NSInteger)thumbnailSize {
    UIImage *resizedImage = [self resizedImageThatFillsBounds:CGSizeMake(thumbnailSize, thumbnailSize)];
    CGRect cropRect = CGRectMake(round((resizedImage.size.width - thumbnailSize) / 2),
                                 round((resizedImage.size.height - thumbnailSize) / 2),
                                 thumbnailSize,
                                 thumbnailSize);
    UIImage *croppedImage = [resizedImage croppedImage:cropRect];
    return croppedImage;
}

- (UIImage *)resizedImageWithBounds:(CGSize)bounds fit:(BOOL)fit {
    CGFloat horizontalRatio;;
    CGFloat verticalRatio;
    
    switch (self.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationRight:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            horizontalRatio = bounds.height / self.size.height;
            verticalRatio = bounds.width / self.size.width;
            break;
            
        default:
            horizontalRatio = bounds.width / self.size.width;
            verticalRatio = bounds.height / self.size.height;
            break;
    }
    
    CGFloat ratio;
    if (fit) {
        ratio = MIN(horizontalRatio, verticalRatio);
    } else {
        ratio = MAX(horizontalRatio, verticalRatio);
    }
    CGSize newSize = CGSizeMake(self.size.width * ratio, self.size.height * ratio);
    return [self resizedImageWithSize:newSize];
}

- (UIImage *)resizedImageThatFillsBounds:(CGSize)bounds {
    return [self resizedImageWithBounds:bounds fit:NO];
}

- (UIImage *)resizedImageThatFitsInBounds:(CGSize)bounds {
    return [self resizedImageWithBounds:bounds fit:YES];
}


#pragma mark -
#pragma mark Private Methods

- (UIImage *)resizedImageWithSize:(CGSize)newSize {
    CGAffineTransform transform = [self transformForOrientation:newSize];

    BOOL drawTransposed;
    switch (self.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            drawTransposed = YES;
            break;
        default:
            drawTransposed = NO;
            break;
    }

    CGRect newRect = CGRectIntegral(CGRectMake(0, 0, newSize.width, newSize.height));
    CGRect transposedRect = CGRectMake(0, 0, newRect.size.height, newRect.size.width);
    CGImageRef imageRef = self.CGImage;

    // Build a context that's the same dimensions as the new size
    CGContextRef bitmap = CGBitmapContextCreate(NULL,
                                                newRect.size.width,
                                                newRect.size.height,
                                                CGImageGetBitsPerComponent(imageRef),
                                                0,
                                                CGImageGetColorSpace(imageRef),
                                                kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedLast);
    NSCAssert(bitmap, @"Bitmap context is NULL");

    // Rotate and/or flip the image if required by its orientation
    CGContextConcatCTM(bitmap, transform);

    // Set the quality level to use when rescaling
    CGContextSetInterpolationQuality(bitmap, kCGInterpolationMedium);

    // Draw into the context; this scales the image
    CGContextDrawImage(bitmap, drawTransposed ? transposedRect : newRect, imageRef);

    // Get the resized image from the context and a UIImage
    CGImageRef newImageRef = CGBitmapContextCreateImage(bitmap);
    UIImage *newImage = [UIImage imageWithCGImage:newImageRef];

    // Clean up
    CGContextRelease(bitmap);
    CGImageRelease(newImageRef);

    return newImage;
}

+ (CGAffineTransform)transformForImageOfSize:(CGSize)imageSize
                                 orientation:(UIImageOrientation)imageOrientation
                                     newSize:(CGSize)newImageSize {

    CGAffineTransform transform = CGAffineTransformIdentity;

    switch (imageOrientation) {
        case UIImageOrientationDown:           // EXIF = 3
        case UIImageOrientationDownMirrored:   // EXIF = 4
            transform = CGAffineTransformTranslate(transform, newImageSize.width, newImageSize.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;

        case UIImageOrientationLeft:           // EXIF = 6
        case UIImageOrientationLeftMirrored:   // EXIF = 5
            transform = CGAffineTransformTranslate(transform, newImageSize.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;

        case UIImageOrientationRight:          // EXIF = 8
        case UIImageOrientationRightMirrored:  // EXIF = 7
            transform = CGAffineTransformTranslate(transform, 0, newImageSize.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;

        default:
            break;
    }

    switch (imageOrientation) {
        case UIImageOrientationUpMirrored:     // EXIF = 2
        case UIImageOrientationDownMirrored:   // EXIF = 4
            transform = CGAffineTransformTranslate(transform, newImageSize.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;

        case UIImageOrientationLeftMirrored:   // EXIF = 5
        case UIImageOrientationRightMirrored:  // EXIF = 7
            transform = CGAffineTransformTranslate(transform, newImageSize.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            
        default:
            break;
    }

    return transform;
}

- (CGAffineTransform)transformForOrientation:(CGSize)newSize {
    return [self.class transformForImageOfSize:self.size orientation:self.imageOrientation newSize:newSize];
}

- (CGRect)cropRectForOrientation:(CGRect)cropRect {
    CGRect finalCropRect = CGRectZero;

    switch (self.imageOrientation) {
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            finalCropRect.origin.x = cropRect.origin.y;
            finalCropRect.origin.y = self.size.width - CGRectGetMaxX(cropRect);
            finalCropRect.size.width = cropRect.size.height;
            finalCropRect.size.height = cropRect.size.width;
            break;

        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            finalCropRect.origin.x = self.size.height - CGRectGetMaxY(cropRect);
            finalCropRect.origin.y = cropRect.origin.x;
            finalCropRect.size.width = cropRect.size.height;
            finalCropRect.size.height = cropRect.size.width;
            break;

        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            finalCropRect.origin.x = self.size.width - CGRectGetMaxX(cropRect);
            finalCropRect.origin.y = self.size.height - CGRectGetMaxY(cropRect);
            finalCropRect.size.width = cropRect.size.width;
            finalCropRect.size.height = cropRect.size.height;
            break;

        default:
            finalCropRect = cropRect;
            break;
    }

    return CGRectIntegral(finalCropRect);
}

@end
