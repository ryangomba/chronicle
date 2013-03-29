#import "CHPhotoView.h"
#import "RGTransformableView.h"

@interface CHFramedImageView : RGTransformableView

@property (nonatomic, strong, readonly) id<CHPhoto> photo;
@property (nonatomic, assign, readonly) CHPhotoImageSize desiredImageSize;
@property (nonatomic, strong, readonly) CHPhotoView *photoView;

- (id)initWithPhoto:(id<CHPhoto>)photo;

- (void)setPhoto:(id<CHPhoto>)photo desiredImageSize:(CHPhotoImageSize)imageSize;

@end
