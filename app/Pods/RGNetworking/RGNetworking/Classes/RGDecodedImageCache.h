//  Copyright 2013-present Ryan Gomba. All rights reserved.

#import "RGTypes.h"

@interface RGDecodedImageCache : NSCache

+ (instancetype)sharedCache;

- (UINSImage *)imageForKey:(NSString *)key;
- (void)setImage:(UINSImage *)image forKey:(NSString *)key;

@end
