#import "CHDirectedViewController.h"

@implementation CHDirectedViewController

@dynamic view;

- (id)init {
    return [super initWithNibName:nil bundle:nil];
}

- (void)loadView {
    [self setView:[[CHDirectedView alloc] initWithFrame:CGRectZero]];
}

@end
