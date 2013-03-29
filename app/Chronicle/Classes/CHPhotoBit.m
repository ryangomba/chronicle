#import "CHPhotoBit.h"
#import "CHModel+Internal.h"

@implementation CHPhotoBit

@dynamic aspectRatio;
@dynamic localIdentifier;
@dynamic mediaModificationDate;

#pragma mark -
#pragma mark Constructors

+ (instancetype)newPhotoBitFromPhoto:(CHPhoto *)photo storyPK:(NSString *)storyPK {
    CHPhotoBit *photoBit = [self newModel];
    photoBit.storyPK = storyPK;
    
    if (photo.mediaType == CHMediaTypeVideo) {
        photoBit.type = CHBitTypeVideo;
    } else {
        photoBit.type = CHBitTypePhoto;
    }
    
    photoBit.localIdentifier = photo.localIdentifier;
    photoBit.mediaModificationDate = [photo.modificationDate timeIntervalSince1970];
    photoBit.aspectRatio = photo.aspectRatio;
    
    return photoBit;
}

@end
