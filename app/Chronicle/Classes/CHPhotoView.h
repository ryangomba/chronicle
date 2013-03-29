#import <UIKit/UIKit.h>
#import "CHPhoto.h"

@interface CHPhotoView : UIImageView

@property (nonatomic, strong, readonly) id<CHPhoto> photo;
@property (nonatomic, assign, readonly) CHPhotoImageSize desiredImageSize;

- (void)setPhoto:(id<CHPhoto>)photo desiredImageSize:(CHPhotoImageSize)imageSize;

@end
