#import "CHPhoto.h"

// TODO move out of here
static NSString * const kCHAssetsLibraryLastImportDateKey = @"assets-library-last-import";

typedef void (^CHAssetsLibraryBlock) (NSArray *images);

@interface CHAssetsLibraryImporter : NSObject

@property (nonatomic, copy) NSArray *allAssets;

+ (instancetype)sharedImporter;

+ (CGSize)assetSizeForImageSize:(CHPhotoImageSize)desiredImageSize;

- (void)startImport;

@end
