#import "CHAppDelegate.h"

#import "CHRootViewController.h"

#import "CHSyncCoordinator.h"

// TEMP
#import "CHBitAssetChangeWatcher.h"
#import "CHDatabase.h"
#import <Photos/Photos.h>

@implementation CHAppDelegate

#pragma mark -
#pragma mark UIApplicationDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    UIWindow *window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [self setWindow:window];
    
    CHRootViewController *rootVC = [[CHRootViewController alloc] init];
    [self.window setRootViewController:rootVC];
    [self.window makeKeyAndVisible];
    
    [CHDatabase fetchAllStoriesWithCompletion:^(NSArray *stories) {
        for (CHStory *story in stories) {
            [CHDatabase fetchAllBitsForStory:story completion:^(NSArray *bits) {
                for (CHBit *bit in bits) {
                    if (bit.type == CHBitTypePhoto) {
//                        CHPhotoBit *mediaBit = (CHPhotoBit *)bit;

                        // update cloud ID & modification date
//                        PHFetchResult *result =
//                        [PHAsset fetchAssetsWithLocalIdentifiers:@[mediaBit.localIdentifier] options:nil];
//                        PHAsset *asset = result.firstObject;
  
                        // re-upload
//                        CHUploadOperation *uploadOperation =
//                        [CHUploadOperation newOperationWithEntityPK:mediaBit.pk
//                                                    localIdentifier:mediaBit.localIdentifier];
//                        [CHDatabase enqueueUploadOperation:uploadOperation];
                    }
                }
            }];
        }
    }];
    
    [[CHBitAssetChangeWatcher sharedChangeWatcher] startWatching];
    [CHSyncCoordinator startSync];
    
    [[UIApplication sharedApplication] registerForRemoteNotifications];
    
    return YES;
}

- (void)application:(UIApplication *)application
didReceiveRemoteNotification:(NSDictionary *)userInfo
fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    
    completionHandler(UIBackgroundFetchResultNewData);
}

@end
