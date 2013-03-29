//  Copyright 2013-present Ryan Gomba. All rights reserved.

#import "RGTypes.h"
#import "RGImageLoader.h"

@protocol RGImageViewDelegate;

@interface RGImageView : UINSImageView<RGImageRequestDelegate>

@property (nonatomic, strong) NSURL *imageURL;
@property (nonatomic, strong) UINSImage *placeholderImage;

@property (nonatomic, weak) id<RGImageViewDelegate> delegate;

@end

@protocol RGImageViewDelegate<NSObject>

@optional
- (void)imageViewLoadedImage:(RGImageView *)imageView;
- (void)imageViewFailedToLoadImage:(RGImageView *)imageView error:(NSError *)error;

@end
