// Copyright 2004-present Facebook. All Rights Reserved.

#import "RGCache.h"

#include <dirent.h>
#include <string>
#include <sys/stat.h>
#include <utime.h>
#include <vector>

#import <RGCore/RGLog.h>
#import <RGCore/RGMacros.h>
#import <RGCore/RGAssert.h>

#import "RGFileInfo.h"
#import "NSString+MD5.h"

#define kRGCacheDefaultCacheSize        (250 * 1024 * 1024) // 250MB
#define kRGCacheDefaultMaxObjectCount   (10000)             // Will start purging random files after cache exceeds 10K files
#define kRGCachePurgeSpilledObjectCount (2000)              // if we're over the max object count, we purge this many subsequent files
#define kRGCacheTrimBackoffInterval     (60*60)             // Back off for: 60 seconds * 60 minutes = 1hr

@interface RGCache () {
    NSCache *_memCache;
    NSFileManager *_fileManager;
    dispatch_queue_t _ioQueue;
    
    NSString *_cachePath;
    
    #if TARGET_OS_IPHONE
    UIBackgroundTaskIdentifier _trimmingTask;
    NSTimeInterval _lastTrimTime;
    #endif
}

@end


@implementation RGCache

#pragma mark -
#pragma mark NSObject

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

+ (instancetype)sharedCache {
    static RGCache *sharedCache;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedCache = [[self alloc] init];
    });
    return sharedCache;
}

- (id)init {
    if ((self = [super init])) {
        _diskCapacity = kRGCacheDefaultCacheSize;
        _maxObjectCount = kRGCacheDefaultMaxObjectCount;
        
        _memCache = [[NSCache alloc] init];
        _ioQueue = dispatch_queue_create("com.instagram.cache_io", DISPATCH_QUEUE_SERIAL);
        
        _fileManager = [NSFileManager new];
        
        NSString *path = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
        path = [path stringByAppendingPathComponent:[[NSBundle mainBundle] bundleIdentifier]];
        _cachePath = [path stringByAppendingPathExtension:@"RGCache"];
        
        [_fileManager createDirectoryAtPath:_cachePath
                withIntermediateDirectories:YES
                                 attributes:nil
                                      error:nil];
        
        #if TARGET_OS_IPHONE
        _trimmingTask = UIBackgroundTaskInvalid;
        _lastTrimTime = -10000; // distant past
        
        // trim disk cache if necessary on app backgrounding
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(startBackgroundCacheTrimmingTask)
                                                     name:UIApplicationWillResignActiveNotification
                                                   object:nil];
        #endif
    }
    return self;
}


#pragma mark -
#pragma mark Public

- (id)objectForKey:(NSString *)key {
    if (!key) {
        return nil;
    }
    
    __block id object = nil;
    dispatch_sync(_ioQueue, ^{
        object = [self io_queue_objectForKey:key];
    });
    return object;
}

- (void)objectForKey:(NSString *)key completion:(void(^)(id object))completion {
    if (!key) {
        completion(nil);
        return;
    }
    
    dispatch_async(_ioQueue, ^{
        id object = [self io_queue_objectForKey:key];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            completion(object);
        });
    });
}

- (void)setObject:(id)object forKey:(NSString *)key {
    [self setObject:object forKey:key completion:nil];
}

- (void)setObject:(id)object forKey:(NSString *)key completion:(void (^)(void))completion {
    if (!key) {
        return;
    }
    
    if (!object) {
        [self removeObjectForKey:key];
        return;
    }
    
    [_memCache setObject:object forKey:key];
    dispatch_async(_ioQueue, ^{
        NSString *path = [self pathFromKey:key];
        BOOL success = [NSKeyedArchiver archiveRootObject:object toFile:path];
        RGAssert(success, @"Could not archive object to cache");
        
        if (completion) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), completion);
        }
    });
}

- (void)removeObjectForKey:(NSString *)key {
    [_memCache removeObjectForKey:key];
    dispatch_async(_ioQueue, ^{
        NSString *path = [self pathFromKey:key];
        [_fileManager removeItemAtPath:path error:nil];
    });
}

- (void)removeAllObjects {
    [_memCache removeAllObjects];
    dispatch_async(_ioQueue, ^{
        BOOL success = [_fileManager removeItemAtPath:_cachePath error:nil];
        if (success) {
            [_fileManager createDirectoryAtPath:_cachePath
                    withIntermediateDirectories:YES
                                     attributes:nil
                                          error:nil];
        }
    });
}


#pragma mark -
#pragma mark Private

// returns number of files removed
- (int)removeExcessFiles {
    StartTimer();
    DIR *cacheDir = opendir([_cachePath UTF8String]);
    if (!cacheDir) {
        RGAssert(0, @"Cache directory could not be opened");
        return 0;
    }
    
    struct dirent buffer;
    struct dirent *dirEntry = NULL;
    
    int fileCount = 0;
    int unlinkCount = 0;
    
    while (readdir_r(cacheDir, &buffer, &dirEntry) == 0 && dirEntry) {
        // skip entries that aren't REGular files.
        if (dirEntry->d_type != DT_REG) {
            continue;
        }
        fileCount++;
        if (fileCount > _maxObjectCount) {
            // start deleting files if we've exceeded _maxObjectCount
            unlink([[_cachePath stringByAppendingPathComponent:@(dirEntry->d_name)] UTF8String]);
            unlinkCount++;
            // stop purging to bound the running time of trimming for very large caches
            if (unlinkCount > kRGCachePurgeSpilledObjectCount) {
                break;
            }
        }
    }
    
    closedir(cacheDir);
    
    PrintTimeElapsedMessage(@"Finished removing excess files");
    DebugLog(@"Enumerated over %d files. Unlinked %d files.", fileCount, unlinkCount);
    
    return unlinkCount;
}

#if TARGET_OS_IPHONE
- (void)startBackgroundCacheTrimmingTask {
    @synchronized(self) {
        if (_trimmingTask != UIBackgroundTaskInvalid) {
            return;
        }
        if (CACurrentMediaTime() - _lastTrimTime < kRGCacheTrimBackoffInterval) {
            return;
        }
        _trimmingTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:nil];
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        StartTimer();
        
        // For large caches we remove files at random. This operation is the fastest option.
        int numFiles = [self removeExcessFiles];
        if (numFiles >= kRGCachePurgeSpilledObjectCount) {
            // we purged a lot of files, but we don't know what the file count is,
            // so to ensure that purging time is bounded we exit here.
            
            PrintTimeElapsedMessage(@"Finished trimming random files");
            @synchronized(self) {
                [[UIApplication sharedApplication] endBackgroundTask:_trimmingTask];
                _trimmingTask = UIBackgroundTaskInvalid;
            }
            return;
        }
        
        // Now we do slower purging, by computing total disk usage, and if
        // necessary sorting files by access time, and deleting in LRU order
        
        NSFileManager *fileManager = [NSFileManager new];
        NSArray *urls = [fileManager contentsOfDirectoryAtURL:[NSURL fileURLWithPath:_cachePath]
                                   includingPropertiesForKeys:@[NSURLContentAccessDateKey, NSURLFileSizeKey]
                                                      options:NSDirectoryEnumerationSkipsSubdirectoryDescendants|NSDirectoryEnumerationSkipsPackageDescendants
                                                        error:nil];
        
        DebugLog(@"Performing LRU over %d files.", urls.count);
        
        off_t diskUsage = 0;
        std::vector<RGFileInfo> fileInfo;
        fileInfo.reserve(urls.count);
        
        for (NSURL *url in urls) {
            // So you might look at these two calls and think "Oh I'll use resourceValuesForKeys: to get both!"
            // Well, stop there, because we tried and it's slower than snails. The documentation claims that it
            // firsts checks the value cache before synchronously fetching data, but as of iOS 7 it didn't appear
            // to be the case.
            
            NSDate *accessDate;
            [url getResourceValue:&accessDate forKey:NSURLContentAccessDateKey error:nil];
            
            NSNumber *fileSize;
            [url getResourceValue:&fileSize forKey:NSURLFileSizeKey error:nil];
            
            if (accessDate && fileSize) {
                off_t sizeInBytes = [fileSize longLongValue];
                diskUsage += sizeInBytes;
                fileInfo.emplace_back((RGFileInfo){
                    .url = url,
                    .accessTime = (time_t)[accessDate timeIntervalSince1970],
                    .fileSize = sizeInBytes,
                    
                });
            }
        }
        PrintTimeElapsedMessage(@"Loaded file infos");
        
        if (diskUsage > _diskCapacity) {
            // sort by access time
            std::sort(fileInfo.begin(), fileInfo.end(), [](const RGFileInfo &f1, const RGFileInfo& f2) {
                return f1.accessTime < f2.accessTime;
            });
            
            off_t sizeToTrim = diskUsage - (_diskCapacity * 0.9);
            off_t runningTotal = 0;
            for (const auto& info : fileInfo) {
                [fileManager removeItemAtURL:info.url error:nil];
                runningTotal += info.fileSize;
                
                if (runningTotal > sizeToTrim) {
                    break;
                }
            }
        }
        
        _lastTrimTime = CACurrentMediaTime();
        
        PrintTimeElapsedMessage(@"Finished trimming old files");
        @synchronized(self) {
            [[UIApplication sharedApplication] endBackgroundTask:_trimmingTask];
            _trimmingTask = UIBackgroundTaskInvalid;
        }
    });
}
#endif

- (NSString *)pathFromKey:(NSString *)key {
    return [_cachePath stringByAppendingPathComponent:[key MD5]];
}

- (id)io_queue_objectForKey:(NSString *)key {
    id object = [_memCache objectForKey:key];
    if (object) {
        return object;
    }
    
    NSString *path = [self pathFromKey:key];
    
    @try {
        object = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
    }
    @catch (NSException *exception) {
        [_fileManager removeItemAtPath:path error:nil];
        object = nil;
    }
    
    if (object) {
        // update the access time for file to now
        utime([path UTF8String], NULL);
        [_memCache setObject:object forKey:key];
    }
    
    return  object;
}

@end
