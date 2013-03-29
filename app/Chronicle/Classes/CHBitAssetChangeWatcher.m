#import "CHBitAssetChangeWatcher.h"

// todo separate?
#import "CHDatabase.h"

#import <Photos/Photos.h>

static NSString * const kLastObservedAssetModificationDateKey = @"last-observed-asset-modification-date-1";

@interface CHBitAssetChangeWatcher ()<PHPhotoLibraryChangeObserver>

@property (nonatomic, strong) PHFetchResult *fetchResult;
@property (nonatomic, strong) dispatch_queue_t assetProcessQueue;

@end

@implementation CHBitAssetChangeWatcher

+ (instancetype)sharedChangeWatcher {
    static CHBitAssetChangeWatcher *watcher;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        watcher = [[CHBitAssetChangeWatcher alloc] init];
    });
    return watcher;
}

- (void)dealloc {
    [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
}

- (instancetype)init {
    if (self = [super init]) {
        [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
    }
    return self;
}

- (dispatch_queue_t)assetProcessQueue {
    if (!_assetProcessQueue) {
        _assetProcessQueue = dispatch_queue_create("com.appthat.chronicle.asset-processing-queue", DISPATCH_QUEUE_SERIAL);
    }
    return _assetProcessQueue;
}

- (void)startWatching {
    dispatch_async(self.assetProcessQueue, ^{
        [self fetchNewlyModifiedAssets];
    });
}

- (void)fetchNewlyModifiedAssets {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDate *referenceDate = [defaults objectForKey:kLastObservedAssetModificationDateKey];

    // noop on first run (just index the assets)
    BOOL ignoreChanges = YES;
    PHFetchOptions *options = [[PHFetchOptions alloc] init];
    if (referenceDate) {
        // HACK
        NSDate *effectiveReferenceDate = [referenceDate dateByAddingTimeInterval:1.0];
        options.predicate = [NSPredicate predicateWithFormat:@"modificationDate > %@", effectiveReferenceDate];
        ignoreChanges = NO;
    }
    
    PHFetchResult *fetchResult = [PHAsset fetchAssetsWithOptions:options];
    [self processFetchResult:fetchResult ignoreChanges:ignoreChanges];
}

- (void)processFetchResult:(PHFetchResult *)fetchResult ignoreChanges:(BOOL)ignoreChanges {
    self.fetchResult = fetchResult;
    
    NSMutableArray *modifiedAssets = [NSMutableArray array];
    [fetchResult enumerateObjectsUsingBlock:^(PHAsset *asset, NSUInteger i, BOOL *stop) {
        [modifiedAssets addObject:asset];
    }];
    
    if (modifiedAssets.count == 0) {
        return;
    }
    
    NSDate *referenceDate = nil;
    for (PHAsset *asset in modifiedAssets) {
        if (!ignoreChanges) {
            [self processAsset:asset];
        }
        
        referenceDate = [asset.modificationDate laterDate:referenceDate];
    }
    
    // TODO too soon? what about if we crash?
    [self updateReferenceDate:referenceDate];
}

- (void)updateReferenceDate:(NSDate *)referenceDate {
    if (!referenceDate) {
        NSAssert(NO, @"No reference date specified");
        return;
    }
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:referenceDate forKey:kLastObservedAssetModificationDateKey];
    [defaults synchronize];
}

- (void)processAsset:(PHAsset *)asset {
    NSLog(@"Processing changed asset: %@", asset);
    
    // TODO separate?
    [self onAssetChanged:asset];
}


#pragma mark -
#pragma mark Bits

- (void)onAssetChanged:(PHAsset *)asset {
    // TODO what to do here?
    [CHDatabase fetchAllBitsWithLocalIdentifier:asset.localIdentifier completion:
     ^(NSArray *bits) {
         for (CHPhotoBit *bit in bits) {
             [self updateBit:bit withAsset:asset];
         }
    }];
}

- (void)updateBit:(CHPhotoBit *)bit withAsset:(PHAsset *)asset {
    // re-upload file
    // update aspect ratio
    // update media modification date?
    CGSize imageSize = CGSizeMake(asset.pixelWidth, asset.pixelHeight);
    CGFloat aspectRatio = imageSize.width / imageSize.height;
    [CHDatabase updateMediaForBit:bit
                   newAspectRatio:aspectRatio
         newMediaModificationDate:asset.modificationDate];
}


#pragma mark -
#pragma mark PHPhotoLibraryChangeObserver

- (void)photoLibraryDidChange:(PHChange *)changeInstance {
    PHFetchResultChangeDetails *changes = [changeInstance changeDetailsForFetchResult:self.fetchResult];
    if (changes) {
        dispatch_async(self.assetProcessQueue, ^{
            [self fetchNewlyModifiedAssets];
        });
    }
}

@end
