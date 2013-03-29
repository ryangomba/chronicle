//  Copyright 2013-present Ryan Gomba. All rights reserved.

#import "RGImageLoader.h"

@interface RGBulkImageRequestManager : NSObject

- (void)bulkFetchImageURLs:(NSArray *)imageURLs priority:(RGImageFetchPriority)priority;
- (void)stopObservingRequests;

@end
