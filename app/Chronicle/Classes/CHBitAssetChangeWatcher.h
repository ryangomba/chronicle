#import <Foundation/Foundation.h>

@interface CHBitAssetChangeWatcher : NSObject

+ (instancetype)sharedChangeWatcher;

- (void)startWatching;

@end
