#import <UIKit/UIKit.h>
#import "CHStory.h"
#import "CHHeaderView.h"

@class CHStoryHeaderView;
@protocol CHStoryHeaderViewDelegate <NSObject>

- (void)storyHeaderViewDidDismiss:(CHStoryHeaderView *)viewController;

@end

@interface CHStoryHeaderView : CHHeaderView

@property (nonatomic, weak) id<CHStoryHeaderViewDelegate> delegate;

- (instancetype)initWithStory:(CHStory *)story;

@end
