//  Copyright 2013-present Ryan Gomba. All rights reserved.

#import "RGImageLoader.h"

#import <RGCore/RGAssert.h>

#import "RGService.h"
#import "RGCache.h"

#define kOperationCancelledKey @"isCancelled"

@interface RGImageLoader () {
    NSMutableDictionary *_currentRequests;
}

@end


@implementation RGImageLoader

#pragma mark -
#pragma mark NSObject

+ (instancetype)sharedImageLoader {
    static RGImageLoader *sharedImageLoader;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedImageLoader = [[self alloc] init];
    });
    return sharedImageLoader;
}

- (id)init {
    if ((self = [super init])) {
        _currentRequests = [[NSMutableDictionary alloc] init];
    }
    return self;
}


#pragma mark -
#pragma mark Public Methods

- (RGRequest *)requestForURL:(NSURL *)url {
    @synchronized(self) {
        return [_currentRequests objectForKey:url];
    }
}

- (void)setRequest:(RGRequest *)request forURL:(NSURL *)url {
    RGAssert(url);
    if (!url) {
        return;
    }
    
    @synchronized(self) {
        if (request) {
            [_currentRequests setObject:request forKey:url];
        } else {
            [_currentRequests removeObjectForKey:url];
        }
    }
}

- (void)loadImageForURL:(NSURL *)url
               priority:(RGImageFetchPriority)priority
               observer:(id<RGImageRequestDelegate>)observer {
    
    if (!url) {
        return;
    }
    
    NSString *cacheKey = url.absoluteString;
    [[RGCache sharedCache] objectForKey:cacheKey completion:^(NSData *imageData) {
        if (imageData) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [observer imageRequest:nil didLoadImageData:imageData forURL:url];
            });
        } else {
            [self doLoadImageForURL:url priority:priority observer:observer];
        }
    }];
}


#pragma mark -
#pragma mark Image Requests

- (void)doLoadImageForURL:(NSURL *)url
                 priority:(RGImageFetchPriority)priority
                 observer:(id<RGImageRequestDelegate>)observer {
    
    RGRequest *request = [self requestForURL:url];
    
    if (request) {
        [request setQueuePriority:(NSOperationQueuePriority)priority];

    } else {
        request = [RGGetRequest requestWithURL:url parameters:nil];
        [request setQueuePriority:(NSOperationQueuePriority)priority];
        
        AFHTTPResponseSerializer *serializer = [AFHTTPResponseSerializer new];
        [serializer setAcceptableContentTypes:[NSSet setWithObjects:@"image/jpeg", @"application/octet-stream", nil]]; // TEMP
        [request setResponseSerializer:serializer];
        
        [self setRequest:request forURL:url];

        [[RGService sharedService] startRawRequest:request responseHandler:
         ^(RGRequest *completedRequest, NSData *responseData, RGRequestError *error) {
             if (error) {
                 [request notifyFailureWithError:error forURL:url];
                 
             } else {
                 NSString *cacheKey = url.absoluteString;
                 [[RGCache sharedCache] setObject:responseData forKey:cacheKey];
                 
                 if ([responseData length]) {
                     [request notifySuccessWithData:responseData forURL:url];
                 } else {
                     [request notifyFailureWithError:nil forURL:url];
                 }
             }
             [request removeDependent:observer];
             [_currentRequests removeObjectForKey:url];
        }];
    }
    
    [request addDependent:observer withPriority:(NSOperationQueuePriority)priority];
    
    [request addObserver:self
              forKeyPath:kOperationCancelledKey
                 options:NSKeyValueObservingOptionNew
                 context:NULL];
}

#pragma mark -
#pragma mark Ending Requests

- (void)removeObserver:(id<RGImageRequestDelegate>)observer forURL:(NSURL *)url {
    RGRequest *request = [self requestForURL:url];
    [request removeDependent:observer];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    
    if ([keyPath isEqual:kOperationCancelledKey]) {
        if ([[change objectForKey:NSKeyValueChangeNewKey] boolValue]) {
            [object removeObserver:self forKeyPath:kOperationCancelledKey];
            [self setRequest:nil forURL:[object request].URL];
        }
    }
}

@end

