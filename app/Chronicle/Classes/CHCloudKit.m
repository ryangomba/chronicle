#import "CHCloudKit.h"
#import <CloudKit/CloudKit.h>
#import "CHDatabase.h"
#import "CHModel+Internal.h"
#import "CHDBModelOperation.h"
#import "CHDBListOperation.h"
#import "CHTextBit.h"
#import <RGCore/RGCore.h>

@implementation CHCloudKit

+ (CKDatabase *)privateDatabase {
    static CKDatabase *privateDatabase;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        CKContainer *container = [CKContainer containerWithIdentifier:@"iCloud.com.ryangomba.Chronicle"];
        privateDatabase = [container privateCloudDatabase];
    });
    return privateDatabase;
}

+ (void)subscribe {
    NSPredicate *storyPredicate = [NSPredicate predicateWithFormat:@"TRUEPREDICATE"];
    CKSubscription *storySubscription = [[CKQuerySubscription alloc] initWithRecordType:@"story" predicate:storyPredicate subscriptionID:@"storySubscription1" options:CKQuerySubscriptionOptionsFiresOnRecordCreation|CKQuerySubscriptionOptionsFiresOnRecordUpdate];
    CKNotificationInfo *storyNotificationInfo = [[CKNotificationInfo alloc] init];
    storyNotificationInfo.desiredKeys = @[];
    storySubscription.notificationInfo = storyNotificationInfo;
    [self.privateDatabase saveSubscription:storySubscription completionHandler:^(CKSubscription *subscription, NSError *error) {
        NSLog(@"%@", error);
    }];
    
    NSPredicate *bitPredicate = [NSPredicate predicateWithFormat:@"TRUEPREDICATE"];
    CKSubscription *bitSubscription = [[CKQuerySubscription alloc] initWithRecordType:@"bit" predicate:bitPredicate subscriptionID:@"bitSubscription1" options:CKQuerySubscriptionOptionsFiresOnRecordCreation|CKQuerySubscriptionOptionsFiresOnRecordUpdate];
    CKNotificationInfo *bitNotificationInfo = [[CKNotificationInfo alloc] init];
    bitNotificationInfo.desiredKeys = @[];
    bitSubscription.notificationInfo = bitNotificationInfo;
    [self.privateDatabase saveSubscription:bitSubscription completionHandler:^(CKSubscription *subscription, NSError *error) {
        NSLog(@"%@", error);
    }];
}

+ (CKRecord *)recordForStory:(CHStory *)story {
    CKRecordID *recordID = [[CKRecordID alloc] initWithRecordName:story.pk];
    CKRecord *record = [[CKRecord alloc] initWithRecordType:@"story" recordID:recordID];
    [story.dictionaryRepresentation enumerateKeysAndObjectsUsingBlock:
     ^(id key, id obj, BOOL *stop) {
         [record setObject:obj forKey:key];
     }];
    return record;
}

+ (CKRecord *)recordForBit:(CHBit *)bit story:(CHStory *)story {
    CKRecordID *recordID = [[CKRecordID alloc] initWithRecordName:bit.pk];
    CKRecord *record = [[CKRecord alloc] initWithRecordType:@"bit" recordID:recordID];
    [story.dictionaryRepresentation enumerateKeysAndObjectsUsingBlock:
     ^(id key, id obj, BOOL *stop) {
         [record setObject:obj forKey:key];
     }];
    return record;
}

+ (void)saveAllStories {
    [CHDatabase fetchAllStoriesWithCompletion:^(NSArray *stories) {
        for (CHStory *story in stories) {
            CKRecord *storyRecord = [self recordForStory:story];
            [self.privateDatabase saveRecord:storyRecord completionHandler:
             ^(CKRecord *savedStoryRecord, NSError *error) {
                 NSLog(@"Saved story with error: %@", error);
            }];
            
            [CHDatabase fetchAllBitsForStory:story completion:^(NSArray *bits) {
                for (CHBit *bit in bits) {
                    CKRecord *bitRecord = [self recordForBit:bit story:story];
                    [self.privateDatabase saveRecord:bitRecord completionHandler:
                     ^(CKRecord *savedBitRecord, NSError *error) {
                         NSLog(@"Saved bit with error: %@", error);
                     }];
                }
            }];
        }
    }];
}

+ (void)fetchAllStoriesWithCompletion:(void (^)(NSArray *stories))completion {
    NSString *syncCursorKey = @"syncCursor-stories";
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDate *syncCursor = [defaults objectForKey:syncCursorKey] ?: [NSDate distantPast];
//    syncCursor = [NSDate distantPast];
    
    NSPredicate *storyPredicate = [NSPredicate predicateWithFormat:@"modificationDate > %@", syncCursor];
    CKQuery *storyQuery = [[CKQuery alloc] initWithRecordType:@"story" predicate:storyPredicate];
    [self.privateDatabase performQuery:storyQuery inZoneWithID:nil completionHandler:
     ^(NSArray *results, NSError *error) {
         NSLog(@"All stories: %lu %@", (unsigned long)results.count, error);
         completion(results);
         
         NSDate *lastModifiedDate = syncCursor;
         for (CKRecord *record in results) {
             lastModifiedDate = [lastModifiedDate laterDate:record.modificationDate];
         }
         [defaults setObject:lastModifiedDate forKey:syncCursorKey];
         [defaults synchronize];
     }];
}

+ (void)fetchAllBitsWithCompletion:(void (^)(NSArray *bits))completion {
    NSString *syncCursorKey = @"syncCursor-bits";
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDate *syncCursor = [defaults objectForKey:syncCursorKey] ?: [NSDate distantPast];
//    syncCursor = [NSDate distantPast];
    
    NSPredicate *bitPredicate = [NSPredicate predicateWithFormat:@"modificationDate > %@", syncCursor];
    CKQuery *bitQuery = [[CKQuery alloc] initWithRecordType:@"bit" predicate:bitPredicate];
    [self.privateDatabase performQuery:bitQuery inZoneWithID:nil completionHandler:
     ^(NSArray *results, NSError *error) {
         NSLog(@"All bits: %lu %@", (unsigned long)results.count, error);
         completion(results);
         
         NSDate *lastModifiedDate = syncCursor;
         for (CKRecord *record in results) {
             lastModifiedDate = [lastModifiedDate laterDate:record.modificationDate];
         }
         [defaults setObject:lastModifiedDate forKey:syncCursorKey];
     }];
}

+ (CHStory *)storyFromRecord:(CKRecord *)record {
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    for (NSString *key in record.allKeys) {
        [dictionary setObject:[record objectForKey:key] forKey:key];
    }
    CHStory *story = [[CHStory alloc] initWithDictionary:dictionary];
    return story;
}

+ (CHBit *)bitFromRecord:(CKRecord *)record {
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    for (NSString *key in record.allKeys) {
        [dictionary setObject:[record objectForKey:key] forKey:key];
    }
    CHBit *bit;
    CHBitType bitType = [dictionary[@"type"] integerValue];
    if (bitType == CHBitTypePhoto) {
        bit = [[CHPhotoBit alloc] initWithDictionary:dictionary];
    } else if (bitType == CHBitTypeText) {
        bit = [[CHTextBit alloc] initWithDictionary:dictionary];
    }
    return bit;
}

+ (void)restoreAllStoriesWithCompletion:(void (^)(BOOL success))completion {
    [self fetchAllStoriesWithCompletion:^(NSArray *stories) {
        for (CKRecord *record in stories) {
            [self handleUpdatedRecord:record];
        }
        
        [self fetchAllBitsWithCompletion:^(NSArray *bits) {
            for (CKRecord *record in bits) {
                [self handleUpdatedRecord:record];
            }
            
            if (completion) {
                completion(YES);
            }
        }];
    }];
}

+ (void)deleteAllStories {
    [self fetchAllStoriesWithCompletion:^(NSArray *stories) {
        for (CKRecord *record in stories) {
            [self.privateDatabase deleteRecordWithID:record.recordID completionHandler:
             ^(CKRecordID *recordID, NSError *error) {
                 NSLog(@"Deleted story with error: %@", error);
            }];
        }
    }];

    [self fetchAllBitsWithCompletion:^(NSArray *bits) {
        for (CKRecord *record in bits) {
            [self.privateDatabase deleteRecordWithID:record.recordID completionHandler:
             ^(CKRecordID *recordID, NSError *error) {
                 NSLog(@"Deleted bit with error: %@", error);
             }];
        }
    }];
}


#pragma mark -
#pragma mark Operations

+ (void)applyDatabaseOperation:(CHDBOperation *)operation
                   saveHandler:(void (^)(CKRecord *savedRecord, NSError *error))completion {
    
    if ([operation isKindOfClass:[CHDBModelOperation class]]) {
        if (operation.type == CHDBOperationTypeInsert) {
            [self applyInsertDatabaseOperation:(CHDBModelOperation *)operation saveHandler:completion];
        } else {
            [self applyUpdateDatabaseOperation:operation saveHandler:completion];
        }
    } else if ([operation isKindOfClass:[CHDBListOperation class]]) {
        [self applyUpdateDatabaseOperation:operation saveHandler:completion];
    }
}

+ (void)applyInsertDatabaseOperation:(CHDBModelOperation *)operation
                         saveHandler:(void (^)(CKRecord *savedRecord, NSError *error))completion {
    
    CKRecordID *recordID = [[CKRecordID alloc] initWithRecordName:operation.entityPK];
    CKRecord *record = [[CKRecord alloc] initWithRecordType:operation.entityName recordID:recordID];
    [operation.info enumerateKeysAndObjectsUsingBlock:
     ^(id key, id obj, BOOL *stop) {
         [record setObject:obj forKey:key];
     }];
    [self.privateDatabase saveRecord:record completionHandler:^(CKRecord *savedRecord, NSError *saveError) {
        if (saveError) {
            completion(nil, saveError);
        } else {
            completion(savedRecord, saveError);
        }
    }];
}

+ (void)applyUpdateDatabaseOperation:(CHDBOperation *)operation
                         saveHandler:(void (^)(CKRecord *savedRecord, NSError *error))completion {
    
    CKRecordID *recordID = [[CKRecordID alloc] initWithRecordName:operation.entityPK];
    [self.privateDatabase fetchRecordWithID:recordID completionHandler:
     ^(CKRecord *fetchedRecord, NSError *fetchError) {
         if (fetchError) {
             completion(nil, fetchError);
         } else {
             [self applyDatabaseOperation:operation toRecord:fetchedRecord];
             [self.privateDatabase saveRecord:fetchedRecord completionHandler:
              ^(CKRecord *savedRecord, NSError *saveError) {
                  if (saveError) {
                      completion(nil, saveError);
                  } else {
                      completion(savedRecord, saveError);
                  }
              }];
         }
     }];
}

+ (void)applyDatabaseOperation:(CHDBOperation *)operation
                    completion:(void (^)(BOOL success))completion {
    
    [self applyDatabaseOperation:operation saveHandler:^(CKRecord *savedRecord, NSError *error) {
        if (error) {
            if (error.code == CKErrorUnknownItem) {
                [CHDatabase deleteDatabaseOperation:operation];
                completion(YES);
            } else {
                NSLog(@"CloudKit Error: %@", error);
            }
            
        } else {
            [CHDatabase deleteDatabaseOperation:operation];
            [self handleUpdatedRecord:savedRecord];
            
            // TODO send push?
        }
        completion(!error);
    }];
}

+ (void)handleUpdatedRecord:(CKRecord *)record {
    if ([record.recordType isEqualToString:@"story"]) {
        CHStory *story = [self storyFromRecord:record];
        [CHDatabase saveRemoteStory:story];

    } else if ([record.recordType isEqualToString:@"bit"]) {
        CHBit *bit = [self bitFromRecord:record];
        [CHDatabase saveRemoteBit:bit];

    } else {
        NSAssert(NO, @"Unsupported record");
    }
}


#pragma mark -
#pragma mark Apply

+ (void)applyDatabaseOperation:(CHDBOperation *)operation toRecord:(CKRecord *)record {
    if ([operation isKindOfClass:[CHDBListOperation class]]) {
        CHDBListOperation *listOperation = (CHDBListOperation *)operation;
        NSArray *existingList = [record objectForKey:listOperation.listKey];
        NSMutableArray *list = [existingList mutableCopy] ?: [NSMutableArray array];
        [list removeObject:listOperation.memberPK];
        if (listOperation.type != CHDBOperationTypeDelete) {
            NSInteger index = MIN_MAX(listOperation.memberIndex, 0, list.count);
            [list insertObject:listOperation.memberPK atIndex:index];
        }
        [record setObject:[list copy] forKey:listOperation.listKey];
        
    } else {
        CHDBModelOperation *modelOperation = (CHDBModelOperation *)operation;
        if (operation.type == CHDBOperationTypeDelete) {
            [record setObject:@(YES) forKey:@"deleted"];
        } else {
            [modelOperation.info enumerateKeysAndObjectsUsingBlock:
             ^(NSString *key, id object, BOOL *stop) {
                [record setObject:object forKey:key];
            }];
        }
    }
}

@end
