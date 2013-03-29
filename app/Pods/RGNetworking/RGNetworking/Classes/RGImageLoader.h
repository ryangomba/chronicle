//  Copyright 2013-present Ryan Gomba. All rights reserved.

#import "RGRequest.h"

typedef NS_ENUM(NSInteger, RGImageFetchPriority) {
    RGImageFetchPriorityPrimaryOnscreen    = NSOperationQueuePriorityHigh,
    RGImageFetchPrioritySecondaryOnscreen  = NSOperationQueuePriorityNormal,
    RGImageFetchPriorityPrimaryOffscreen   = NSOperationQueuePriorityLow,
    RGImageFetchPrioritySecondaryOffscreen = NSOperationQueuePriorityVeryLow,
} ;

@protocol RGImageRequestDelegate;

@interface RGImageLoader : NSObject

+ (instancetype)sharedImageLoader;

- (RGRequest *)requestForURL:(NSURL *)url;

- (void)loadImageForURL:(NSURL *)url
               priority:(RGImageFetchPriority)priority
               observer:(id<RGImageRequestDelegate>)observer;

- (void)removeObserver:(id<RGImageRequestDelegate>)observer
                forURL:(NSURL *)url;

@end
