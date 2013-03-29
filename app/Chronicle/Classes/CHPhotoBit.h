#import "CHPhoto.h"
#import "CHBit.h"

@interface CHPhotoBit : CHBit<CHPhoto>

@property (nonatomic, assign) CGFloat aspectRatio;
@property (nonatomic, strong) NSString *localIdentifier;
@property (nonatomic, assign) NSTimeInterval mediaModificationDate;

+ (instancetype)newPhotoBitFromPhoto:(CHPhoto *)photo storyPK:(NSString *)storyPK;

@end
