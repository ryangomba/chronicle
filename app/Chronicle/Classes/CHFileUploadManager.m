#import "CHFileUploadManager.h"

#import "CHDatabase.h"
#import <RGImage/RGImage.h>

// TODO MOVE
#import <Photos/Photos.h>
#import "CHFileUploader.h"

@interface CHFileUploadManager ()

@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) NSMutableDictionary *operationsByEntityPK;
@property (nonatomic, strong) NSMutableDictionary *uploadRequestsByOperationPK;
@property (nonatomic, assign, readwrite) NSInteger ongoingOperationCount;

@end

@implementation CHFileUploadManager

+ (void)startUploads {
    [[self sharedSyncManager] resumeSyncing];
}

+ (void)stopUploads {
    [[self sharedSyncManager] pauseSyncing];
}

+ (instancetype)sharedSyncManager {
    static id object;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        object = [[self alloc] init];
    });
    return object;
}

- (instancetype)init {
    if (self = [super init]) {
        _operationsByEntityPK = [[NSMutableDictionary alloc] init];
        _uploadRequestsByOperationPK = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)resumeSyncing {
    if (!_timer) {
        self.timer = [NSTimer timerWithTimeInterval:1.0
                                             target:self
                                           selector:@selector(onTimerFired)
                                           userInfo:nil
                                            repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
    }
}

- (void)pauseSyncing {
    [self.timer invalidate];
    self.timer = nil;
}

- (void)onTimerFired {
    [self sync];
}

- (void)sync {
    NSAssert([NSThread isMainThread], @"Expects main thread");

    // TODO
    return;
    
    // TODO register for changes to query instead of re-fetching everything all the time
//    [CHDatabase fetchAllUploadOperationsWithCompletion:^(NSArray *operations) {
//        for (CHUploadOperation *operation in operations) {
//            CHUploadOperation *existingOperation = self.operationsByEntityPK[operation.entityPK];
//            if (existingOperation) {
//                if (operation.date.timeIntervalSince1970 > existingOperation.date.timeIntervalSince1970) {
//                    // operation is newer, cancel the old one
//                    [self invalidateOperation:existingOperation];
//                    [self processOperation:operation];
//                    
//                } else if (operation.date.timeIntervalSince1970 < existingOperation.date.timeIntervalSince1970) {
//                    // operation is old, discard
//                    [self invalidateOperation:operation];
//                }
//            } else {
//                [self processOperation:operation];
//            }
//        }
//    }];
}

- (void)processOperation:(CHUploadOperation *)operation {
    self.operationsByEntityPK[operation.entityPK] = operation;
    self.ongoingOperationCount = self.uploadRequestsByOperationPK.count;
    
    [self.class loadMediaFileForAssetWithLocalIdentifier:operation.localIdentifier completion:^(NSData *data, NSString *extension) {
        [self processMediaFileForOperation:operation data:data extension:extension];
    }];
}

- (void)processMediaFileForOperation:(CHUploadOperation *)operation data:(NSData *)data extension:(NSString *)extension {
    if (self.operationsByEntityPK[operation.entityPK] != operation) {
        // operation was aborted
        // TODO cancel asset fetch earlier
        return;
    }
    
    if (data) {
        self.uploadRequestsByOperationPK[operation.pk] =
        [self.class uploadFileData:data key:operation.entityPK extension:extension completion:^(BOOL success) {
            [self finishOperation:operation shouldDeleteModel:success];
        }];
        
    } else {
        NSLog(@"Error: No data found for media");
        [self finishOperation:operation shouldDeleteModel:NO];
    }
}

- (void)finishOperation:(CHUploadOperation *)operation shouldDeleteModel:(BOOL)shouldDeleteModel {
    if (self.operationsByEntityPK[operation.entityPK] == operation) {
        [self.operationsByEntityPK removeObjectForKey:operation.entityPK];
    }
    [self.uploadRequestsByOperationPK removeObjectForKey:operation.pk];
    self.ongoingOperationCount = self.uploadRequestsByOperationPK.count;
    if (shouldDeleteModel) {
        [CHDatabase deleteUploadOperation:operation];
    }
}

- (void)invalidateOperation:(CHUploadOperation *)operation {
    NSLog(@"Invalidating upload operation because a newer one for the same entity exists");
    [CHFileUploader cancelUpload:self.uploadRequestsByOperationPK[operation.pk]];
    [self finishOperation:operation shouldDeleteModel:YES];
}

// TODO MOVE

+ (void)loadMediaFileForAssetWithLocalIdentifier:(NSString *)localIdentifier
                                      completion:(void (^)(NSData *data, NSString *extension))completion {
    PHAsset *asset = [PHAsset fetchAssetsWithLocalIdentifiers:@[localIdentifier] options:nil].firstObject;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [self handleAsset:asset completion:completion];
    });
}

+ (void)handleAsset:(PHAsset *)asset completion:(void (^)(NSData *data, NSString *extension))completion {
    if (asset.mediaType == PHAssetMediaTypeImage) {
        PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
        options.resizeMode = PHImageRequestOptionsResizeModeExact;
        options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
        
        [[PHImageManager defaultManager] requestImageForAsset:asset
                                                   targetSize:PHImageManagerMaximumSize
                                                  contentMode:PHImageContentModeAspectFill
                                                      options:options
                                                resultHandler:^(UIImage *image, NSDictionary *info)
         {
             dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                 CGFloat width = 560.0; // TODO don't hardcode
                 UIImage *scaledImage = [image resizedImageThatFitsInBounds:CGSizeMake(width, FLT_MAX)];
                 NSData *scaledData = UIImageJPEGRepresentation(scaledImage, 0.95);
                 if (completion) {
                     completion(scaledData, @"jpg");
                 }
             });
         }];
        
    } else if (asset.mediaType == PHAssetMediaTypeVideo) {
        PHVideoRequestOptions *options = [[PHVideoRequestOptions alloc] init];
        options.deliveryMode = PHVideoRequestOptionsDeliveryModeHighQualityFormat;
        
        [[PHImageManager defaultManager] requestExportSessionForVideo:asset options:options exportPreset:AVAssetExportPresetMediumQuality resultHandler:^(AVAssetExportSession *exportSession, NSDictionary *info) {
            NSString *assetID = [asset.localIdentifier stringByReplacingOccurrencesOfString:@"/" withString:@"-"];
            NSString *filename = [NSString stringWithFormat:@"%@.mp4", assetID];
            NSString *outputURLString = [NSTemporaryDirectory() stringByAppendingPathComponent:filename];
            NSURL *outputURL = [[NSURL alloc] initFileURLWithPath:outputURLString];
            exportSession.outputURL = outputURL;
            exportSession.outputFileType = AVFileTypeMPEG4;

            [exportSession exportAsynchronouslyWithCompletionHandler:^{
                NSData *data = [NSData dataWithContentsOfURL:outputURL];
                if (completion) {
                    completion(data, @"mp4");
//                    [[NSFileManager defaultManager] removeItemAtURL:outputURL error:nil];
                }
            }];
        }];
        
    } else {
        if (completion) {
            completion(nil, nil);
        }
    }
}

+ (id)uploadFileData:(NSData *)data
                 key:(NSString *)key
           extension:(NSString *)extension
          completion:(void (^)(BOOL success))completion {
    
    NSString *remoteKey = [NSString stringWithFormat:@"media/%@.%@", key, extension];
    NSString *MIMEType = [extension isEqual:@"jpg"] ? @"image/jpeg" : @"video/mp4";
    
    return [CHFileUploader uploadData:data
                                  key:remoteKey
                             MIMEType:MIMEType
                           completion:^(BOOL success, NSError *error)
    {
        NSLog(@"Uploaded file with error: %@", error);
        if (completion) {
            completion(success);
        }
    }];
}

@end
