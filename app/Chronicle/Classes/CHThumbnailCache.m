#import "CHThumbnailCache.h"

#define kCountLimit 21

@implementation CHThumbnailCache

- (id)init {
    if (self = [super init]) {
        [self setName:@"thumbnailCache"];
        [self setCountLimit:kCountLimit];
    }
    return self;
}

+ (instancetype)sharedCache {
    static id object;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        object = [[self alloc] init];
    });
    return object;
}

@end
