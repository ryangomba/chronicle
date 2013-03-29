//  Copyright 2013-present Ryan Gomba. All rights reserved.

#import "RGBulkImageRequestManager.h"

@interface RGBulkImageRequestManager()<RGImageRequestDelegate>

@property (nonatomic, strong) NSMutableSet *imageURLs;

@end


@implementation RGBulkImageRequestManager

#pragma mark -
#pragma mark NSObject

- (void)dealloc {
    [self stopObservingRequests];
}


#pragma mark -
#pragma mark Properties

- (NSMutableSet *)imageURLs {
    if (!_imageURLs) {
        _imageURLs = [NSMutableSet set];
    }
    return _imageURLs;
}


#pragma mark -
#pragma mark Public

- (void)bulkFetchImageURLs:(NSArray *)imageURLs priority:(RGImageFetchPriority)priority {
    RGImageLoader *loader = [RGImageLoader sharedImageLoader];
    for (NSURL *imageURL in imageURLs) {
        [loader loadImageForURL:imageURL priority:priority observer:self];
    }
    
    @synchronized(self) {
        [self.imageURLs addObjectsFromArray:imageURLs];
    }
}

- (void)stopObservingRequests {
    NSArray *imageURLs;
    
    @synchronized(self) {
        imageURLs = [self.imageURLs copy];
        [self.imageURLs removeAllObjects];
    }
    
    for (NSURL *imageURL in imageURLs) {
        [[RGImageLoader sharedImageLoader] removeObserver:self forURL:imageURL];
    }
}


#pragma mark -
#pragma mark Image Request Delegate

- (void)imageRequest:(RGRequest *)request
    didLoadImageData:(NSData *)imageData
              forURL:(NSURL *)url {
    
    @synchronized(self) {
        [self.imageURLs removeObject:url];
    }
}

- (void)imageRequest:(RGRequest *)request
    didFailWithError:(NSError *)error
              forURL:(NSURL *)url {

    @synchronized(self) {
        [self.imageURLs removeObject:url];
    }
}

@end
