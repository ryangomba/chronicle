#import <Foundation/Foundation.h>

@class CHStoryListDataSource;
@protocol CHStoryListDataSourceDelegate <NSObject>

- (void)storyListDataSource:(CHStoryListDataSource *)dataSource
           didUpdateResults:(NSArray *)results;

@end

@interface CHStoryListDataSource : NSObject

@property (nonatomic, weak) id<CHStoryListDataSourceDelegate> delegate;

@end
