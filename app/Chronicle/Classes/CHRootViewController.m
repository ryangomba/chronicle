#import "CHRootViewController.h"

#import "RGLogInViewController.h"
#import "CHAssetsLibraryImporter.h"
#import "CHDatabase.h"

@interface CHRootViewController ()

@property (nonatomic, strong, readwrite) UINavigationController *loginNC;
@property (nonatomic, strong, readwrite) CHMainAppViewController *mainAppVC;

@end


@implementation CHRootViewController

#pragma mark -
#pragma mark NSObject

- (id)init {
    if (self =[super initWithNibName:nil bundle:nil]) {
        // TODO: implement onLogIn, onLogOut listeners
    }
    return self;
}


#pragma mark -
#pragma mark View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    // TODO: implement login
    BOOL isLoggedIn = YES;
    if (isLoggedIn) {
        [self startMainApp];
    } else {
        [self showLogInController];
    }
}


#pragma mark -
#pragma mark Notification Listeners

- (void)onLogIn {
    [self resetSyncProcesses];
    [self startMainApp];
}

- (void)onLogOut {
    [self showLogInController];
    [self stopSyncProcesses];
}


#pragma mark -
#pragma mark Private

- (void)showLogInController {
    if (self.mainAppVC) {
        [self.mainAppVC willMoveToParentViewController:nil];
        [self.mainAppVC.view removeFromSuperview];
        [self.mainAppVC removeFromParentViewController];
        [self setMainAppVC:nil];
    }
    
    RGLogInViewController *loginVC = [[RGLogInViewController alloc] init];
    UINavigationController *loginNC = [[UINavigationController alloc] initWithRootViewController:loginVC];
    [self setLoginNC:loginNC];
    
    [self addChildViewController:loginNC];
    [self.view addSubview:loginNC.view];
    [loginNC didMoveToParentViewController:self];
}

- (void)startMainApp {
    if (self.loginNC) {
        [self.loginNC willMoveToParentViewController:nil];
        [self.loginNC.view removeFromSuperview];
        [self.loginNC removeFromParentViewController];
        [self setLoginNC:nil];
    }
    
    CHMainAppViewController *mainAppVC = [[CHMainAppViewController alloc] init];
    [self setMainAppVC:mainAppVC];
    
    [self addChildViewController:mainAppVC];
    [self.view addSubview:mainAppVC.view];
    [mainAppVC didMoveToParentViewController:self];

    // TODO: re-implement
    // [self fetchFriendsList];

    [self beginSyncProcesses];
}


#pragma mark -
#pragma mark Sync

- (void)beginSyncProcesses {
    dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC));
    dispatch_after(delay, dispatch_get_main_queue(), ^{
        [[CHAssetsLibraryImporter sharedImporter] startImport];
    });
}

- (void)stopSyncProcesses {
    //
}

- (void)resetSyncProcesses {
    //
}


#pragma mark -
#pragma mark Status bar

- (BOOL)prefersStatusBarHidden {
    return YES;
}

@end
