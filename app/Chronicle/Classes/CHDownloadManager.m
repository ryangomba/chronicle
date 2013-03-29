#import "CHDownloadManager.h"

#import "CHCloud.h"

@interface CHDownloadManager ()

@property (nonatomic, assign) BOOL syncing;
@property (nonatomic, strong) NSTimer *timer;

@end

@implementation CHDownloadManager

+ (void)startSync {
    [self sharedSyncManager];
}

+ (instancetype)sharedSyncManager {
    static id object;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        object = [[self alloc] init];
    });
    return object;
}

- (instancetype)init {
    if (self = [super init]) {
        self.timer = [NSTimer timerWithTimeInterval:5.0
                                             target:self
                                           selector:@selector(onTimerFired)
                                           userInfo:nil
                                            repeats:YES];
        
        [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
    }
    return self;
}

- (void)onTimerFired {
    [self sync];
}

- (void)sync {
    if (self.syncing) {
        return;
    }
    self.syncing = YES;
    
    NSLog(@"Fetching all records");
    [CHCloud restoreAllStoriesWithCompletion:^(BOOL success) {
        self.syncing = NO;
    }];
}

@end
