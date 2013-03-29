#import "CHSyncManager.h"

#import "CHDatabase.h"
#import "CHDBModelOperation.h"
#import "CHCloud.h"

@interface CHSyncManager ()

@property (nonatomic, assign) BOOL syncing;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) NSArray *operations;

@end

@implementation CHSyncManager

+ (void)startSync {
    [[self sharedSyncManager] resumeSyncing];
}

+ (void)stopSync {
    [[self sharedSyncManager] pauseSyncing];
}

+ (instancetype)sharedSyncManager {
    static id object;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        object = [[self alloc] init];
    });
    return object;
}

- (void)resumeSyncing {
    if (!_timer) {
        self.timer = [NSTimer timerWithTimeInterval:1.0
                                             target:self
                                           selector:@selector(onTimerFired)
                                           userInfo:nil
                                            repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
    }
}

- (void)pauseSyncing {
    [self.timer invalidate];
    self.timer = nil;
}

- (void)onTimerFired {
    [self sync];
}

- (void)sync {
    if (self.syncing) {
        return;
    }
    self.syncing = YES;
    
    [CHDatabase fetchAllDatabaseOperationsWithCompletion:^(NSArray *operations) {
        self.operations = operations;
        
        CHDBOperation *operation = self.operations.firstObject;
        
        if (operation) {
            NSLog(@"Applying: %@", operation);
            [CHCloud applyDatabaseOperation:operation completion:^(BOOL success) {
                if (success) {
                    //
                }
                self.syncing = NO;
            }];
        } else {
            self.syncing = NO;
        }
    }];
}

@end
