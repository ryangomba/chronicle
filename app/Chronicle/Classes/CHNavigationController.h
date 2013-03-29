#import <UIKit/UIKit.h>

@interface CHNavigationController : UIViewController

- (id)initWithRootViewController:(UIViewController *)viewController;

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated;
- (void)popViewControllerAnimated:(BOOL)animated;

@end
