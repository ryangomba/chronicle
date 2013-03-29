#import "RGLogInViewController.h"

#import "CHDatabase.h"

@interface RGLogInViewController ()

@end


@implementation RGLogInViewController

#pragma mark -
#pragma mark NSObject

- (id)init {
    if (self = [super initWithNibName:nil bundle:nil]) {
        [self setTitle:NSLocalizedString(@"Log In", nil)];
        
        [self.navigationItem setRightBarButtonItem:
         [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Done", nil)
                                          style:UIBarButtonItemStylePlain
                                         target:self
                                         action:@selector(onLogInTapped)]];
    }
    return self;
}


#pragma mark -
#pragma mark View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    [self.view setBackgroundColor:[UIColor whiteColor]];
}


#pragma mark -
#pragma mark Private

- (void)onLogInTapped {
    // TODO: implement
}

@end
