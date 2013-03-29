#import "CHDBOperation.h"

@protocol CHCloud <NSObject>

+ (void)subscribe;

+ (void)saveAllStories;
+ (void)restoreAllStoriesWithCompletion:(void (^)(BOOL success))completion;
+ (void)deleteAllStories;

+ (void)applyDatabaseOperation:(CHDBOperation *)operation
                    completion:(void (^)(BOOL success))completion;

@end
