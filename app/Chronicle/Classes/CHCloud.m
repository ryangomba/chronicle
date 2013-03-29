#import "CHCloud.h"

#import "CHCloudKit.h"
#import "CHCustomCloud.h"

@implementation CHCloud

+ (Class<CHCloud>)cloudProvider {
    return [CHCustomCloud class];
}

+ (void)subscribe {
    [[self cloudProvider] subscribe];
}

+ (void)saveAllStories {
    [[self cloudProvider] saveAllStories];
}

+ (void)restoreAllStoriesWithCompletion:(void (^)(BOOL success))completion {
    [[self cloudProvider] restoreAllStoriesWithCompletion:completion];
}

+ (void)deleteAllStories {
    [[self cloudProvider] deleteAllStories];
}

+ (void)applyDatabaseOperation:(CHDBOperation *)operation
                    completion:(void (^)(BOOL success))completion {
    
    [[self cloudProvider] applyDatabaseOperation:operation completion:completion];
}

@end
