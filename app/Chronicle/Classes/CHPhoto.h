#import "CHImageLoader.h"

typedef NS_ENUM(NSInteger, CHMediaType) {
    CHMediaTypePhoto            = 0,
    CHMediaTypeScreenshot       = 1,
    CHMediaTypeVideo            = 2,
};

typedef NS_ENUM(NSInteger, CHPhotoImageSize) {
    CHPhotoImageSizeUnknown     = 0,
    CHPhotoImageSizeThumbnail   = 1,
    CHPhotoImageSizeSmall       = 2,
};

@protocol CHPhoto <NSObject>

- (NSString *)pk;
- (CGFloat)aspectRatio;
- (NSString *)localIdentifier;

@end

@interface CHPhoto : NSObject<CHPhoto>

@property (nonatomic, readwrite) NSString *pk;
@property (nonatomic, readwrite) CGFloat aspectRatio;

@property (nonatomic, assign) CHMediaType mediaType;
@property (nonatomic, strong) NSDate *creationDate;
@property (nonatomic, strong) NSDate *modificationDate;
@property (nonatomic, assign) double latitude;
@property (nonatomic, assign) double longitude;
@property (nonatomic, strong) NSString *localIdentifier;
@property (nonatomic, assign) BOOL isFavorite;

@property (nonatomic, readonly) NSString *day;

@end
