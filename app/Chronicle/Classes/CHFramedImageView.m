#import "CHFramedImageView.h"
#import "CHConstants.h"
#import <QuartzCore/QuartzCore.h>

@interface CHFramedImageView ()

@property (nonatomic, strong, readwrite) CHPhotoView *photoView;
@property (nonatomic, strong, readwrite) UIImageView *frameView;

@end


@implementation CHFramedImageView

#pragma mark -
#pragma mark NSObject

- (void)dealloc {
    //
}

- (id)initWithPhoto:(id<CHPhoto>)photo {
    if (self = [super initWithFrame:CGRectZero]) {
        _desiredImageSize = CHPhotoImageSizeUnknown;
        
        [self setPhoto:photo desiredImageSize:_desiredImageSize];
        
        [self setBackgroundColor:HEX_COLOR(0x181818)];

        [self.photoView setFrame:self.bounds];
        [self.contentView addSubview:self.photoView];
        
        [self.frameView setFrame:self.bounds];
        [self.contentView addSubview:self.frameView];
    }
    return self;
}


#pragma mark -
#pragma mark Properties

- (id)attachedModel {
    return self.photo;
}

- (CHPhotoView *)photoView {
    if (!_photoView) {
        _photoView = [[CHPhotoView alloc] initWithFrame:CGRectZero];
        [_photoView setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
        [_photoView setContentMode:UIViewContentModeScaleAspectFill];
        [_photoView setBackgroundColor:[UIColor grayColor]];
    }
    return _photoView;
}

- (UIImageView *)frameView {
    if (!_frameView) {
        _frameView = [[UIImageView alloc] initWithFrame:CGRectZero];
        [_frameView setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
        
        UIImage *borderImage = [UIImage imageNamed:@"photo-border.png"];
        borderImage = [borderImage stretchableImageWithLeftCapWidth:1.0f topCapHeight:1.0f];
        [_frameView setImage:borderImage];
    }
    return _frameView;
}

- (void)setShadowed:(BOOL)shadowed animated:(BOOL)animated {
    [super setShadowed:shadowed animated:animated];
    
    [self.frameView setHidden:!shadowed];
}


#pragma mark -
#pragma mark Public

- (void)setPhoto:(id<CHPhoto>)photo desiredImageSize:(CHPhotoImageSize)imageSize {
    _photo = photo;
    _desiredImageSize = imageSize;
    
    self.aspectRatio = [photo aspectRatio];
    
    [self.photoView setPhoto:self.photo desiredImageSize:imageSize];
}

@end
