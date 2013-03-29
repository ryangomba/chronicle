#import <UIKit/UIKit.h>
#import "CHStory.h"

@class CHStoryViewController;
@protocol CHStoryViewControllerDelegate <NSObject>

- (void)storyViewControllerDidDismiss:(CHStoryViewController *)controller;

@end

@interface CHStoryViewController : UIViewController

@property (nonatomic, strong, readonly) UICollectionView *collectionView;
@property (nonatomic, strong, readonly) CHStory *story;

@property (nonatomic, weak) id<CHStoryViewControllerDelegate> delegate;

- (id)initWithStory:(CHStory *)story;

@end
