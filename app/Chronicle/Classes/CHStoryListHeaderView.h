#import <UIKit/UIKit.h>
#import "CHStory.h"
#import "CHHeaderView.h"

@class CHStoryListHeaderView;
@protocol CHStoryListHeaderViewDelegate <NSObject>

- (void)storyListHeaderView:(CHStoryListHeaderView *)viewController
                didAddStory:(CHStory *)story;

@end

@interface CHStoryListHeaderView : CHHeaderView

@property (nonatomic, weak) id<CHStoryListHeaderViewDelegate> delegate;

@end
