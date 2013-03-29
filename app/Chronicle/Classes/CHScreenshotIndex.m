#import "CHScreenshotIndex.h"
#import <RGNetworking/RGNetworking.h>

@implementation CHScreenshotIndex

static NSSet *sScreenshotSizes;

+ (void)initialize {
    sScreenshotSizes =
    [NSSet setWithObjects:
     // short iPhone
     SIZE_VALUE(CGSizeMake(320, 480)),
     SIZE_VALUE(CGSizeMake(480, 320)),
     SIZE_VALUE(CGSizeMake(640, 960)),
     SIZE_VALUE(CGSizeMake(960, 640)),
     // tall iPhone
     SIZE_VALUE(CGSizeMake(640, 1136)),
     SIZE_VALUE(CGSizeMake(1136, 640)),
     // iPad
     SIZE_VALUE(CGSizeMake(768, 1024)),
     SIZE_VALUE(CGSizeMake(1024, 768)),
     SIZE_VALUE(CGSizeMake(1536, 2048)),
     SIZE_VALUE(CGSizeMake(2048, 1536)),
     nil];
}

+ (BOOL)imageSizeQualifiesAsScreenshot:(CGSize)imageSize {
    return [sScreenshotSizes containsObject:SIZE_VALUE(imageSize)];
}

@end
