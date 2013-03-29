//  Copyright 2013-present Ryan Gomba. All rights reserved.

#import "RGImageView.h"

#import <RGCore/RGAssert.h>

#import "RGImageLoader.h"
#import "RGDecodedImageCache.h"
#import "UIImage+Decode.h"

@implementation RGImageView

#pragma mark -
#pragma mark NSObject

- (void)dealloc {
    [[RGImageLoader sharedImageLoader] removeObserver:self forURL:self.imageURL];
}


#pragma mark -
#pragma mark Property Methods

- (void)setPlaceholderImage:(UINSImage *)placeholderImage {
    _placeholderImage = placeholderImage;

    [self setImage:_placeholderImage];
}


#pragma mark -
#pragma mark Decoding

- (void)setImageWithData:(NSData *)imageData {
    if (!imageData) {
        [self setImage:self.placeholderImage];
        return;
    }

    NSURL *decodedImageURL = self.imageURL;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        UINSImage *decodedImage = [UINSImage decodedImageWithData:imageData];
        RGAssert(decodedImage);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (![decodedImageURL isEqual:self.imageURL]) {
                return;
            }
            
            if (decodedImage) {
                [self setImage:decodedImage];
                [self notifyDelegateOfSuccess];
                
                NSString *cacheKey = self.imageURL.absoluteString;
                [[RGDecodedImageCache sharedCache] setImage:decodedImage forKey:cacheKey];
                
            } else {
                [self notifyDelegateOfFailure:nil];
            }
        });
    });
}

- (void)setImage:(UINSImage *)image {
    if (!image) {
        image = self.placeholderImage;
    }
    [super setImage:image];
}


#pragma mark -
#pragma mark Public Methods

- (void)setImageURL:(NSURL *)imageURL {
    // if this is the same image url and we already have the image, return
    if ([imageURL isEqual:_imageURL] && self.image && self.image != _placeholderImage) {
        [self notifyDelegateOfSuccess];
        return;
    }

    // change the image url and stop listening for the old one to finish
    // but don't cancel it, because someone else might be waiting on it to load
    [[RGImageLoader sharedImageLoader] removeObserver:self forURL:self.imageURL];

    _imageURL = imageURL;

    // see if this images has already been decoded
    // if it has, set our UIImage directly and notify the delegate of success
    NSString *cacheKey = _imageURL.absoluteString;
    UINSImage *image = [[RGDecodedImageCache sharedCache] imageForKey:cacheKey];
    if (image) {
        [self setImage:image];
        [self notifyDelegateOfSuccess];
        return;
    }

    // since we'll at least need time to decode, set the placeholder temporarily
    [self setImage:self.placeholderImage];

    // go load the image, from disk cache, or from the network
    [[RGImageLoader sharedImageLoader] loadImageForURL:imageURL priority:RGImageFetchPriorityPrimaryOnscreen observer:self];
}


#pragma mark -
#pragma mark Delegate Notifications

- (void)notifyDelegateOfSuccess {
    if ([self.delegate respondsToSelector:@selector(imageViewLoadedImage:)]) {
        [self.delegate imageViewLoadedImage:self];
    }
}

- (void)notifyDelegateOfFailure:(NSError *)error {
    if([self.delegate respondsToSelector:@selector(imageViewFailedToLoadImage:error:)]) {
        [self.delegate imageViewFailedToLoadImage:self error:error];
    }
}


#pragma mark -
#pragma mark RGImageRequestDelegate

- (void)imageRequest:(RGRequest *)request
    didLoadImageData:(NSData *)imageData
              forURL:(NSURL *)url {
    
    if ([url isEqual:self.imageURL]) {
        [self setImageWithData:imageData];
    }
}

- (void)imageRequest:(RGRequest *)request
    didFailWithError:(NSError *)error
              forURL:(NSURL *)url {
    
    if ([url isEqual:self.imageURL]) {
        [self notifyDelegateOfFailure:error];
    }
}

@end

