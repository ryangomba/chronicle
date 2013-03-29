#import "RGTransformableView.h"
#import "CHPhoto.h"
#import "CHTextBit.h"

@class CHBitPickerViewController;
@protocol CHBitPickerViewControllerDelegate <NSObject>

- (void)bitPickerViewController:(CHBitPickerViewController *)controller
          willBeginDraggingView:(RGTransformableView *)view
                       forPhoto:(CHPhoto *)photo;

- (void)bitPickerViewController:(CHBitPickerViewController *)controller
      willBeginDraggingTextView:(RGTransformableView *)view
                         ofType:(CHTextBitTextType)textType;

- (void)bitPickerDidDismiss:(CHBitPickerViewController *)controller;

@end

@interface CHBitPickerViewController : UIViewController

@property (nonatomic, weak) id<CHBitPickerViewControllerDelegate> delegate;

+ (instancetype)sharedController;

@end
