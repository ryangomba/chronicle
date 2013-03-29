#import "CHMainAppViewController.h"

#import "CHNavigationController.h"
#import "CHStoryListViewController.h"
#import "CHStoryViewController.h"

@interface CHMainAppViewController ()<CHStoryListViewControllerDelegate, CHStoryViewControllerDelegate>

@property (nonatomic, strong) CHNavigationController *photosNC;

@end


@implementation CHMainAppViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nil bundle:nil]) {
        //
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    UIEdgeInsets safeAreaInsets = self.view.safeAreaInsets;
    NSLog(@"%f", safeAreaInsets.top);
    CHStoryListViewController *storiesVC = [[CHStoryListViewController alloc] init];
    storiesVC.delegate = self;
    
    self.photosNC = [[CHNavigationController alloc] initWithRootViewController:storiesVC];
//    [self.photosNC.navigationBar setBarTintColor:[UIColor blackColor]];
//    [self.photosNC.navigationBar setTintColor:[UIColor whiteColor]];
//    [self.photosNC.navigationBar setTranslucent:NO];
//    [self.photosNC setNavigationBarHidden:YES];
    
    [self addChildViewController:self.photosNC];
    [self.view addSubview:self.photosNC.view];
    [self.photosNC didMoveToParentViewController:self];
}


#pragma mark -
#pragma mark CHStoryListViewControllerDelegate

- (void)storyListViewController:(CHStoryListViewController *)viewController
                 didSelectStory:(CHStory *)story {
    
    CHStoryViewController *storyVC = [[CHStoryViewController alloc] initWithStory:story];
    storyVC.delegate = self;
    [self.photosNC pushViewController:storyVC animated:YES];
}


#pragma mark -
#pragma mark CHStoryViewControllerDelegate

- (void)storyViewControllerDidDismiss:(CHStoryViewController *)controller {
    [self.photosNC popViewControllerAnimated:YES];
}

@end
