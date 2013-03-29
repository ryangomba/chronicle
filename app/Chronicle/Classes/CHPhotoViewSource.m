#import "CHPhotoViewSource.h"
#import "CHTextBit.h"
#import "CHFramedVideoView.h"

@interface CHPhotoViewSource ()

@property (nonatomic, strong) NSMapTable *photoViews;

@end


@implementation CHPhotoViewSource

#pragma mark -
#pragma mark Properties

- (NSMapTable *)photoViews {
    if (!_photoViews) {
        _photoViews = [NSMapTable strongToWeakObjectsMapTable];
    }
    return _photoViews;
}


#pragma mark -
#pragma mark CHPhotoViewSource

- (CHFramedImageView *)viewForPhoto:(CHPhoto *)photo {
    CHFramedImageView *imageView = [self.photoViews objectForKey:photo.pk];
    
    if (!imageView) {
        if (photo.mediaType == CHMediaTypeVideo) {
            imageView = [[CHFramedVideoView alloc] initWithPhoto:photo];
        } else {
            imageView = [[CHFramedImageView alloc] initWithPhoto:photo];
        }
//        [self.photoViews setObject:imageView forKey:photo.pk];
    }
    
    return imageView;
}

- (CHFramedImageView *)viewForMediaBit:(CHBit<CHPhoto> *)mediaBit {
    CHFramedImageView *imageView = [self.photoViews objectForKey:mediaBit.pk];
    
    if (!imageView) {
        if (mediaBit.type == CHBitTypeVideo) {
            imageView = [[CHFramedVideoView alloc] initWithPhoto:mediaBit];
        } else {
            imageView = [[CHFramedImageView alloc] initWithPhoto:mediaBit];
        }
        [self.photoViews setObject:imageView forKey:mediaBit.pk];
    }
    
    if (imageView.photo != mediaBit) { // HACK
        [imageView setPhoto:mediaBit desiredImageSize:imageView.desiredImageSize];
    }
    
    return imageView;
}

- (void)setView:(CHFramedImageView *)view forPhoto:(id<CHPhoto>)photo {
    [self.photoViews setObject:view forKey:photo.pk];
}

@end

///////////////////////

@interface CHTextViewSource ()

@property (nonatomic, strong) NSMapTable *views;

@end


@implementation CHTextViewSource

#pragma mark -
#pragma mark Properties

- (NSMapTable *)views {
    if (!_views) {
        _views = [NSMapTable strongToWeakObjectsMapTable];
    }
    return _views;
}


#pragma mark -
#pragma mark CHTextViewSource

- (CHTransformableTextView *)viewForTextBit:(CHTextBit *)textBit {
    CHTransformableTextView *view = [self.views objectForKey:textBit.pk];
    
    if (!view) {
        view = [[CHTransformableTextView alloc] init];
        view.bit = textBit;
        [self.views setObject:view forKey:textBit.pk];
    }
    
    return view;
}

- (void)setView:(CHTransformableTextView *)view forTextBit:(CHTextBit *)textBit {
    [self.views setObject:view forKey:textBit.pk];
}

@end
