#import "CHNetworkImageSource.h"
#import <RGNetworking/RGNetworking.h>

@interface CHNetworkImageSource ()<RGImageRequestDelegate> {
    void (^_sourceLoadBlock)(UIImage *image, NSData *imageData);
}

@property (nonatomic, strong) NSURL *imageURL;

@end


@implementation CHNetworkImageSource

#pragma mark -
#pragma mark NSObject

- (id)initWithImageURL:(NSURL *)imageURL {
    if (self = [super init]) {
        [self setImageURL:imageURL];
    }
    return self;
}


#pragma mark -
#pragma mark RGImageSource

- (void)loadCacheKey:(void (^)(NSString *cacheKey))completion {
    completion(self.imageURL.absoluteString);
}

- (void)loadImage:(void (^)(UIImage *image, NSData *imageData))completion {
    _sourceLoadBlock = [completion copy];
    
    RGImageLoader *loader = [RGImageLoader sharedImageLoader];
    [loader loadImageForURL:self.imageURL
                   priority:RGImageFetchPriorityPrimaryOnscreen
                   observer:self];
}

- (void)cancel {
    [[RGImageLoader sharedImageLoader] removeObserver:self forURL:self.imageURL];
}


#pragma mark -
#pragma mark RGImageRequestDelegate

- (void)imageRequest:(RGRequest *)request
    didLoadImageData:(NSData *)imageData
              forURL:(NSURL *)url {
    
    _sourceLoadBlock(nil, imageData);
}

- (void)imageRequest:(RGRequest *)request
    didFailWithError:(NSError *)error
              forURL:(NSURL *)url {
    
    _sourceLoadBlock(nil, nil);
}

@end
