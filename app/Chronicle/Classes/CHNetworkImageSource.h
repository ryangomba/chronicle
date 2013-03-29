#import "CHImageLoader.h"

@interface CHNetworkImageSource : NSObject<RGImageSource>

- (id)initWithImageURL:(NSURL *)imageURL;

@end
