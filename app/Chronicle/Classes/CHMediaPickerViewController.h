#import "RGTransformableView.h"
#import "CHPhoto.h"

@class CHMediaPickerViewController;
@protocol CHMediaPickerViewControllerDelegate <NSObject>

- (void)mediaPickerViewController:(CHMediaPickerViewController *)controller
            willBeginDraggingView:(RGTransformableView *)view
                         forPhoto:(CHPhoto *)photo;

@end

@interface CHMediaPickerViewController : UIViewController

@property (nonatomic, weak) id<CHMediaPickerViewControllerDelegate> delegate;

- (void)fetchData;

@end
