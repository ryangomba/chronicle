#import <Foundation/Foundation.h>
#import "CHPhoto.h"

@interface CHPhotoLoader : NSObject

+ (id<RGImageSource>)sourceForPhoto:(id<CHPhoto>)photo imageSize:(CHPhotoImageSize)imageSize;

@end
