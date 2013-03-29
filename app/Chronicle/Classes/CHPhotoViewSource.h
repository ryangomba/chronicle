#import <Foundation/Foundation.h>
#import "CHFramedImageView.h"
#import "CHTransformableTextView.h"
#import "CHBit.h"
#import "CHTextBit.h"
#import "CHPhoto.h"

@protocol CHPhotoViewSource <NSObject>

- (CHFramedImageView *)viewForPhoto:(CHPhoto *)photo;
- (CHFramedImageView *)viewForMediaBit:(CHBit<CHPhoto> *)mediaBit;
- (void)setView:(CHFramedImageView *)view forPhoto:(id<CHPhoto>)photo;

@end

@interface CHPhotoViewSource : NSObject<CHPhotoViewSource>

@end

///////////////////////
// TODO move

@protocol CHTextViewSource <NSObject>

- (CHTransformableTextView *)viewForTextBit:(CHTextBit *)textBit;
- (void)setView:(CHTransformableTextView *)view forTextBit:(CHTextBit *)textBit;

@end

@interface CHTextViewSource : NSObject<CHTextViewSource>

@end
