//  Copyright 2013-present Ryan Gomba. All rights reserved.

#import "RGDecodedImageCache.h"

@implementation RGDecodedImageCache

+ (instancetype)sharedCache {
    static RGDecodedImageCache *sharedCache;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedCache = [[self alloc] init];
    });
    return sharedCache;
}

- (id)init {
    if (self = [super init]) {
        // 25MB for mobile, 100MB for desktop
        #if TARGET_OS_IPHONE
        NSUInteger maxDiskSize = 25000000;
        #else
        NSUInteger maxDiskSize = 100000000;
        #endif

        // 4 bytes per pixel
        NSUInteger maxCost = maxDiskSize / 4;
        [self setTotalCostLimit:maxCost];
    }
    return self;
}

- (UINSImage *)imageForKey:(NSString *)key {
    return [self objectForKey:key];
}

- (void)setImage:(UINSImage *)image forKey:(UINSImage *)key {
    CGSize imageSize = [image size];
    NSUInteger imageCost = imageSize.width * imageSize.height;
    [self setObject:image forKey:key cost:imageCost];
}

@end

