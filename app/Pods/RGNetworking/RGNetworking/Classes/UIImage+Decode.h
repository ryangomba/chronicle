//  Copyright 2013-present Ryan Gomba. All rights reserved.

#import "RGTypes.h"

@interface UINSImage (Decode)

+ (UINSImage *)decodedImageWithData:(NSData *)data;

- (NSData *)JPEGDataWithQuality:(CGFloat)quality;

@end

#if !TARGET_OS_IPHONE
@interface NSImage (UI)
- (id)initWithCGImage:(CGImageRef)CGImage;
+ (instancetype)imageWithCGImage:(CGImageRef)CGImage;
@end
#endif

@interface CIImage (Initialization)

+ (instancetype)imageWithImage:(UINSImage *)image;

@end
