#import "CHStoryListDataSource.h"

#import "CHDatabase.h"
#import "YapDatabase.h"
#import "YapSet.h"
#import "YapCollectionKey.h"

@interface CHStoryListDataSource ()

@property (nonatomic, strong) YapDatabaseConnection *connection;

@end

@implementation CHStoryListDataSource

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.connection endLongLivedReadTransaction];
}

- (instancetype)init {
    if (self = [super init]) {
        self.connection = [[CHDatabase database] newConnection];
        [self.connection beginLongLivedReadTransaction];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onDatabaseModified:)
                                                     name:YapDatabaseModifiedNotification
                                                   object:[CHDatabase database]];
    }
    return self;
}

- (void)setDelegate:(id<CHStoryListDataSourceDelegate>)delegate {
    _delegate = delegate;
    
    [self updateResults];
}

- (void)updateResults {
    NSMutableArray *stories = [[NSMutableArray alloc] init];
    [self.connection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        [transaction enumerateKeysAndObjectsInCollection:@"stories" usingBlock:
         ^(NSString *key, CHStory *story, BOOL *stop) {
             [stories addObject:story];
         }];
    }];
    [stories sortUsingComparator:^NSComparisonResult(CHStory *story1, CHStory *story2) {
        return [story2.date compare:story1.date];
    }];
    [self.delegate storyListDataSource:self didUpdateResults:stories];
}

- (void)onDatabaseModified:(NSNotification *)notification {
    NSArray *notifications = [self.connection beginLongLivedReadTransaction];
    
    if ([self.connection hasObjectChangeForCollection:@"stories" inNotifications:notifications]) {
        [self updateResults];
    }
}

@end
