#import <Foundation/Foundation.h>
#import "CHImageLoader.h"

@interface CHAssetImageSource : NSObject<RGImageSource>

- (id)initWithLocalIdentifier:(NSString *)localIdentifier;

@property (nonatomic, assign) CGSize assetSize;

@end
