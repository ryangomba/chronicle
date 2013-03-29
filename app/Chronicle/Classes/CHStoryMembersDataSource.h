#import "CHStory.h"

@class CHStoryMembersDataSource;
@protocol CHStoryMembersDataSourceDelegate <NSObject>

- (void)storyMembersDataSource:(CHStoryMembersDataSource *)dataSource
              didUpdateResults:(NSArray *)results;

@end

@interface CHStoryMembersDataSource : NSObject

@property (nonatomic, weak) id<CHStoryMembersDataSourceDelegate> delegate;

- (instancetype)initWithStory:(CHStory *)story;

@end
