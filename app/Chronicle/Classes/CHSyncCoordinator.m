#import "CHSyncCoordinator.h"

#import "CHSyncManager.h"
#import "CHDownloadManager.h"
#import "CHCloud.h"
#import "CHFileUploadManager.h"
#import <UIKit/UIKit.h>
#import <AFNetworking/AFNetworkReachabilityManager.h>

@implementation CHSyncCoordinator

+ (void)load {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserverForName:UIApplicationDidEnterBackgroundNotification
                    object:nil
                     queue:nil
                usingBlock:^(NSNotification *note) {
                    NSLog(@"Pausing syncing due to app background");
                    [self pauseSyncing];
                }];
    [nc addObserverForName:UIApplicationWillEnterForegroundNotification
                    object:nil
                     queue:nil
                usingBlock:^(NSNotification *note) {
                    NSLog(@"Resuming syncing (??) due to app foreground");
                    [self resumeSyncingIfNetworkReachable];
                }];
    [nc addObserverForName:AFNetworkingReachabilityDidChangeNotification
                    object:nil
                     queue:nil
                usingBlock:^(NSNotification *note) {
                    [self resumeSyncingIfNetworkReachable];
                }];
}

+ (void)startSync {
    [CHCloud subscribe];
    [CHDownloadManager startSync];
    
    [self resumeSyncingIfNetworkReachable];
    
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
}

+ (void)resumeSyncing {
    [CHSyncManager startSync];
    [CHFileUploadManager startUploads];
}

+ (void)pauseSyncing {
    [CHSyncManager stopSync];
    [CHFileUploadManager stopUploads];
}

+ (void)resumeSyncingIfNetworkReachable {
    if ([AFNetworkReachabilityManager sharedManager].isReachable) {
        NSLog(@"Resuming syncing due to reachable network");
        [self resumeSyncing];
    } else {
        NSLog(@"Pausing syncing due to unreachable network");
        [self pauseSyncing];
    }
}

@end
