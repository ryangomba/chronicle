#import <Foundation/Foundation.h>

@interface CHFileUploadManager : NSObject

+ (void)startUploads;
+ (void)stopUploads;

+ (instancetype)sharedSyncManager;

@property (nonatomic, assign, readonly) NSInteger ongoingOperationCount;

@end
