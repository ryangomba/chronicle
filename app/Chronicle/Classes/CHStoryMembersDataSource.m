#import "CHStoryMembersDataSource.h"

#import "CHDatabase.h"
#import "YapDatabase.h"
#import "YapSet.h"
#import "YapCollectionKey.h"

@interface CHStoryMembersDataSource ()

@property (nonatomic, strong) CHStory *story;
@property (nonatomic, strong) YapDatabaseConnection *connection;

@end

@implementation CHStoryMembersDataSource

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.connection endLongLivedReadTransaction];
}

- (instancetype)initWithStory:(CHStory *)story {
    if (self = [super init]) {
        self.story = story;
        
        self.connection = [[CHDatabase database] newConnection];
        [self.connection beginLongLivedReadTransaction];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onDatabaseModified:)
                                                     name:YapDatabaseModifiedNotification
                                                   object:[CHDatabase database]];
    }
    return self;
}

- (void)setDelegate:(id<CHStoryMembersDataSourceDelegate>)delegate {
    _delegate = delegate;
    
    [self updateResults];
}

- (void)updateResults {
    NSMutableArray *people = [[NSMutableArray alloc] init];
    [self.connection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        CHStory *story = [transaction objectForKey:self.story.pk inCollection:@"stories"];
        NSArray *peoplePKs = story.peoplePKs.allObjects;
        [transaction enumerateObjectsForKeys:peoplePKs inCollection:@"people" unorderedUsingBlock:^(NSUInteger keyIndex, id object, BOOL *stop) {
            [people addObject:object];
        }];
    }];
    [self.delegate storyMembersDataSource:self didUpdateResults:people];
}

- (void)onDatabaseModified:(NSNotification *)notification {
    NSArray *notifications = [self.connection beginLongLivedReadTransaction];
    
    if ([self.connection hasObjectChangeForKey:self.story.pk inCollection:@"stories" inNotifications:notifications]) {
        [self updateResults];
    }
}

@end
