#import <UIKit/UIKit.h>
#import "CHStory.h"

@class CHStoryListViewController;
@protocol CHStoryListViewControllerDelegate <NSObject>

- (void)storyListViewController:(CHStoryListViewController *)viewController
                 didSelectStory:(CHStory *)story;

@end

@interface CHStoryListViewController : UIViewController

@property (nonatomic, weak) id<CHStoryListViewControllerDelegate> delegate;

@end
