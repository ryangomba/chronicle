#import "CHDatabase.h"

#import "YapDatabase.h"
#import "CHModel+Internal.h"
#import "CHDBModelOperation.h"
#import "CHDBListOperation.h"
#import "CHUploadOperation.h"
#import <RGCore/RGCore.h>

static NSString * const kPeopleCollectionKey = @"people";
static NSString * const kStoriesCollectionKey = @"stories";
static NSString * const kOperationsCollectionKey = @"operations";
static NSString * const kUploadOperationsCollectionKey = @"upload-operations";

@implementation CHDatabase

#pragma mark -
#pragma mark Database

+ (YapDatabase *)database {
    static YapDatabase *database;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
        NSString *applicationSupportDirectory = [paths firstObject];
        NSString *databasePath = [applicationSupportDirectory stringByAppendingString:@"database.sqlite"];
        database = [[YapDatabase alloc] initWithURL:[[NSURL alloc] initFileURLWithPath:databasePath]];
    });
    return database;
}

+ (YapDatabaseConnection *)writeConnection {
    static YapDatabaseConnection *connection;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        connection = [[self database] newConnection];
    });
    return connection;
}


#pragma mark -
#pragma mark Helpers

+ (BOOL)collectionKeyRepresentsStory:(NSString *)collectionKey {
    return [collectionKey hasPrefix:@"sb"];
}

+ (NSString *)collectionKeyForBitsForStoryPK:(NSString *)storyPK {
    return [NSString stringWithFormat:@"sb-%@", storyPK];
}


#pragma mark -
#pragma mark Fetches

+ (void)fetchAllPeopleWithCompletion:(void (^)(NSArray *friends))completion {
    NSMutableArray *people = [NSMutableArray array];
    [[[self database] newConnection] asyncReadWithBlock:^(YapDatabaseReadTransaction *transaction) {
        [transaction enumerateKeysAndObjectsInCollection:kPeopleCollectionKey usingBlock:
         ^(NSString *key, CHPerson *person, BOOL *stop) {
             [people addObject:person];
        }];
    } completionBlock:^{
        completion(people);
    }];
}

+ (void)fetchAllStoriesWithCompletion:(void (^)(NSArray *stories))completion {
    NSMutableArray *stories = [NSMutableArray array];
    [[[self database] newConnection] asyncReadWithBlock:^(YapDatabaseReadTransaction *transaction) {
        [transaction enumerateKeysAndObjectsInCollection:kStoriesCollectionKey usingBlock:
         ^(NSString *key, CHStory *story, BOOL *stop) {
             [stories addObject:story];
         }];
        
    } completionBlock:^{
        completion(stories);
    }];
}

+ (void)fetchAllBitsForStory:(CHStory *)story completion:(void (^)(NSArray *bits))completion {
    NSMutableArray *bits = [NSMutableArray array];
    [[[self database] newConnection] asyncReadWithBlock:^(YapDatabaseReadTransaction *transaction) {
        NSMutableDictionary *bitMap = [NSMutableDictionary dictionary];
        NSString *collection = [self collectionKeyForBitsForStoryPK:story.pk];
        [transaction enumerateKeysAndObjectsInCollection:collection usingBlock:
         ^(NSString *key, CHBit *bit, BOOL *stop) {
             [bitMap setObject:bit forKey:key];
         }];

        CHStory *savedStory = [transaction objectForKey:story.pk inCollection:kStoriesCollectionKey];
        for (NSString *bitPK in savedStory.bitPKs) {
            CHBit *bit = bitMap[bitPK];
            if (bit) {
                [bits addObject:bit];
            }
        }
        
    } completionBlock:^{
        completion(bits);
    }];
}

+ (void)fetchAllPeopleForStory:(CHStory *)story completion:(void (^)(NSArray *people))completion {
    NSMutableArray *people = [NSMutableArray array];
    [[[self database] newConnection] asyncReadWithBlock:^(YapDatabaseReadTransaction *transaction) {
        NSArray *peoplePKs = story.peoplePKs.allObjects;
        [transaction enumerateObjectsForKeys:peoplePKs inCollection:kPeopleCollectionKey unorderedUsingBlock:
         ^(NSUInteger keyIndex, CHPerson *person, BOOL *stop) {
             [people addObject:person];
        }];
        
    } completionBlock:^{
        completion(people);
    }];
}

// TODO very inefficient
+ (void)fetchAllBitsWithLocalIdentifier:(NSString *)localIdentifier completion:(void (^)(NSArray *bits))completion {
    NSMutableArray *bits = [NSMutableArray array];
    [[[self database] newConnection] asyncReadWithBlock:^(YapDatabaseReadTransaction *transaction) {
        [transaction enumerateKeysAndObjectsInAllCollectionsUsingBlock:
         ^(NSString *collection, NSString *key, CHBit *bit, BOOL *stop) {
             if ([bit isKindOfClass:[CHPhotoBit class]]) {
                 CHPhotoBit *photoBit = (CHPhotoBit *)bit;
                 if ([photoBit.localIdentifier isEqual:localIdentifier]) {
                     [bits addObject:bit];
                 }
             }
         } withFilter:^BOOL(NSString *collection, NSString *key) {
             return [self collectionKeyRepresentsStory:collection];
         }];
        
    } completionBlock:^{
        completion(bits);
    }];
}


#pragma mark -
#pragma mark Mutations

+ (void)addStory:(CHStory *)story {
    CHDBModelOperation *operation =
    [CHDBModelOperation newOperationOfType:CHDBOperationTypeInsert
                                entityName:@"story"
                            collectionName:@"all"
                                  entityPK:story.pk
                                      info:story.dictionaryRepresentation];
    [self enqueueDatabaseOperation:operation];
    
    [[self writeConnection] readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        [transaction setObject:story forKey:story.pk inCollection:kStoriesCollectionKey];
    }];
}

+ (void)deleteStory:(CHStory *)story {
    CHDBModelOperation *operation =
    [CHDBModelOperation newOperationOfType:CHDBOperationTypeDelete
                                entityName:@"story"
                            collectionName:@"all"
                                  entityPK:story.pk
                                      info:nil];
    [self enqueueDatabaseOperation:operation];
    
    [[self writeConnection] readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        [transaction removeObjectForKey:story.pk inCollection:kStoriesCollectionKey];
    }];
}

+ (void)changeText:(NSString *)text forBit:(CHTextBit *)bit {
    CHDBModelOperation *operation =
    [CHDBModelOperation newOperationOfType:CHDBOperationTypeUpdate
                                entityName:@"bit"
                            collectionName:bit.storyPK
                                  entityPK:bit.pk
                                      info:@{@"text": text}];
    [self enqueueDatabaseOperation:operation];

    [[self writeConnection] readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        NSString *collection = [self collectionKeyForBitsForStoryPK:bit.storyPK];
        CHBit *savedBit = [transaction objectForKey:bit.pk inCollection:collection];
        [self applyDatabaseOperation:operation toModel:savedBit];
        [transaction setObject:savedBit forKey:bit.pk inCollection:collection];
    }];
    
    bit.text = text;
}

+ (void)insertBit:(CHBit *)bit atIndex:(NSInteger)index story:(CHStory *)story {
    if (bit.type == CHBitTypePhoto || bit.type == CHBitTypeVideo) {
        CHPhotoBit *mediaBit = (CHPhotoBit *)bit;
        CHUploadOperation *uploadOperation =
        [CHUploadOperation newOperationWithEntityPK:mediaBit.pk
                                    localIdentifier:mediaBit.localIdentifier];
        [self enqueueUploadOperation:uploadOperation];
    }
    
    CHDBModelOperation *modelOperation =
    [CHDBModelOperation newOperationOfType:CHDBOperationTypeInsert
                                entityName:@"bit"
                            collectionName:story.pk
                                  entityPK:bit.pk
                                      info:bit.dictionaryRepresentation];
    [self enqueueDatabaseOperation:modelOperation];
    
    CHDBListOperation *listOperation =
    [CHDBListOperation newOperationOfType:CHDBOperationTypeInsert
                               entityName:@"story"
                           collectionName:@"all"
                                 entityPK:story.pk
                                  listKey:@"bitPKs"
                                 memberPK:bit.pk
                              memberIndex:index];
    [self enqueueDatabaseOperation:listOperation];
    
    [[self writeConnection] readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        CHStory *savedStory = [transaction objectForKey:story.pk inCollection:kStoriesCollectionKey];
        [self applyDatabaseOperation:listOperation toModel:savedStory];
        [transaction setObject:savedStory forKey:story.pk inCollection:kStoriesCollectionKey];

        NSString *collection = [self collectionKeyForBitsForStoryPK:story.pk];
        [transaction setObject:bit forKey:bit.pk inCollection:collection];
    }];
    
    [self applyDatabaseOperation:listOperation toModel:story];
}

+ (void)moveBit:(CHBit *)bit toIndex:(NSInteger)toIndex story:(CHStory *)story {
    CHDBListOperation *listOperation =
    [CHDBListOperation newOperationOfType:CHDBOperationTypeUpdate
                               entityName:@"story"
                           collectionName:@"all"
                                 entityPK:story.pk
                                  listKey:@"bitPKs"
                                 memberPK:bit.pk
                              memberIndex:toIndex];
    [self enqueueDatabaseOperation:listOperation];
    
    [[self writeConnection] readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        CHStory *savedStory = [transaction objectForKey:story.pk inCollection:kStoriesCollectionKey];
        [self applyDatabaseOperation:listOperation toModel:savedStory];
        [transaction setObject:savedStory forKey:story.pk inCollection:kStoriesCollectionKey];
    }];
    
    [self applyDatabaseOperation:listOperation toModel:story];
}

+ (void)removeBit:(CHBit *)bit story:(CHStory *)story {
    CHDBListOperation *listOperation =
    [CHDBListOperation newOperationOfType:CHDBOperationTypeDelete
                               entityName:@"story"
                           collectionName:@"all"
                                 entityPK:story.pk
                                  listKey:@"bitPKs"
                                 memberPK:bit.pk
                              memberIndex:-1];
    [self enqueueDatabaseOperation:listOperation]; // TODO move this into transaction?
    
    CHDBModelOperation *operation =
    [CHDBModelOperation newOperationOfType:CHDBOperationTypeDelete
                                entityName:@"bit"
                            collectionName:story.pk
                                  entityPK:bit.pk
                                      info:nil];
    [self enqueueDatabaseOperation:operation];
    
    [[self writeConnection] readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        CHStory *savedStory = [transaction objectForKey:story.pk inCollection:kStoriesCollectionKey];
        [self applyDatabaseOperation:listOperation toModel:savedStory];
        [transaction setObject:savedStory forKey:story.pk inCollection:kStoriesCollectionKey];

        NSString *collection = [self collectionKeyForBitsForStoryPK:story.pk];
        [transaction removeObjectForKey:bit.pk inCollection:collection];
    }];
    
    [self applyDatabaseOperation:listOperation toModel:story];
}

+ (void)updateMediaForBit:(CHPhotoBit *)bit
           newAspectRatio:(CGFloat)newAspectRatio
 newMediaModificationDate:(NSDate *)newMediaModificationDate {
    
    CHUploadOperation *uploadOperation =
    [CHUploadOperation newOperationWithEntityPK:bit.pk localIdentifier:bit.localIdentifier];
    [self enqueueUploadOperation:uploadOperation];
    
    CHDBModelOperation *modelOperation =
    [CHDBModelOperation newOperationOfType:CHDBOperationTypeUpdate
                                entityName:@"bit"
                            collectionName:bit.storyPK
                                  entityPK:bit.pk
                                      info:@{
                                             @"aspectRatio": @(newAspectRatio),
                                             @"mediaModificationDate": @([newMediaModificationDate timeIntervalSince1970]),
                                             }];
    [self enqueueDatabaseOperation:modelOperation];
    
    [[self writeConnection] readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        NSString *collection = [self collectionKeyForBitsForStoryPK:bit.storyPK];
        CHBit *savedBit = [transaction objectForKey:bit.pk inCollection:collection];
        [self applyDatabaseOperation:modelOperation toModel:savedBit];
        [transaction setObject:savedBit forKey:bit.pk inCollection:collection];
    }];
    
    [self applyDatabaseOperation:modelOperation toModel:bit];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:kCHNotificationBitModifiedExternally object:bit];
    });
}

+ (void)addPeople:(NSArray *)people {
    [[self writeConnection] readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        for (CHPerson *person in people) {
            [transaction setObject:person forKey:person.pk inCollection:kPeopleCollectionKey];
        }
    }];
}

+ (void)addPerson:(CHPerson *)person story:(CHStory *)story {
    CHDBListOperation *listOperation =
    [CHDBListOperation newOperationOfType:CHDBOperationTypeInsert
                               entityName:@"story"
                           collectionName:@"all"
                                 entityPK:story.pk
                                  listKey:@"peoplePKs"
                                 memberPK:person.pk
                              memberIndex:1000];
    [self enqueueDatabaseOperation:listOperation];
    
    [[self writeConnection] readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        CHStory *savedStory = [transaction objectForKey:story.pk inCollection:kStoriesCollectionKey];
        [self applyDatabaseOperation:listOperation toModel:savedStory];
        [transaction setObject:savedStory forKey:story.pk inCollection:kStoriesCollectionKey];
    }];
    
    [self applyDatabaseOperation:listOperation toModel:story];
}

+ (void)removePerson:(CHPerson *)person story:(CHStory *)story {
    CHDBListOperation *listOperation =
    [CHDBListOperation newOperationOfType:CHDBOperationTypeDelete
                               entityName:@"story"
                           collectionName:@"all"
                                 entityPK:story.pk
                                  listKey:@"peoplePKs"
                                 memberPK:person.pk
                              memberIndex:-1];
    [self enqueueDatabaseOperation:listOperation];
    
    [[self writeConnection] readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        CHStory *savedStory = [transaction objectForKey:story.pk inCollection:kStoriesCollectionKey];
        [self applyDatabaseOperation:listOperation toModel:savedStory];
        [transaction setObject:savedStory forKey:story.pk inCollection:kStoriesCollectionKey];
    }];
    
    [self applyDatabaseOperation:listOperation toModel:story];
}


#pragma mark -
#pragma mark Operations

+ (void)fetchAllDatabaseOperationsWithCompletion:(void (^)(NSArray *operations))completion {
    __block NSArray *operations;
    [[[self database] newConnection] asyncReadWithBlock:^(YapDatabaseReadTransaction *transaction) {
        operations = [self collectAllDatabaseOperationsWithTransaction:transaction];
    } completionBlock:^{
        completion(operations);
    }];
}

+ (NSArray *)collectAllDatabaseOperationsWithTransaction:(YapDatabaseReadTransaction *)transaction {
    NSMutableArray *operations = [NSMutableArray array];
    [transaction enumerateKeysAndObjectsInCollection:kOperationsCollectionKey usingBlock:
     ^(NSString *key, id object, BOOL *stop) {
         [operations addObject:object];
    }];
    return [operations sortedArrayUsingComparator:^NSComparisonResult(CHDBOperation *op1, CHDBOperation *op2) {
        return [op1.date compare:op2.date];
    }];
}

+ (void)enqueueDatabaseOperation:(CHDBOperation *)databaseOperation {
    [[self writeConnection] readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        [transaction setObject:databaseOperation forKey:databaseOperation.pk inCollection:kOperationsCollectionKey];
    }];
}

+ (void)deleteDatabaseOperation:(CHDBOperation *)databaseOperation {
    [[self writeConnection] readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        [transaction removeObjectForKey:databaseOperation.pk inCollection:kOperationsCollectionKey];
    }];
}


#pragma mark -
#pragma mark Uploads

+ (void)fetchAllUploadOperationsWithCompletion:(void (^)(NSArray *operations))completion {
    __block NSMutableArray *operations = [[NSMutableArray alloc] init];
    [[[self database] newConnection] asyncReadWithBlock:^(YapDatabaseReadTransaction *transaction) {
        [transaction enumerateKeysAndObjectsInCollection:kUploadOperationsCollectionKey usingBlock:
         ^(NSString *key, id object, BOOL *stop) {
             [operations addObject:object];
         }];
    } completionBlock:^{
        completion(operations);
    }];
}

+ (void)enqueueUploadOperation:(CHUploadOperation *)uploadOperation {
    [[self writeConnection] readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        [transaction setObject:uploadOperation forKey:uploadOperation.pk inCollection:kUploadOperationsCollectionKey];
    }];
}

+ (void)deleteUploadOperation:(CHUploadOperation *)uploadOperation {
    [[self writeConnection] readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        [transaction removeObjectForKey:uploadOperation.pk inCollection:kUploadOperationsCollectionKey];
    }];
}


#pragma mark -
#pragma mark Apply

+ (void)applyDatabaseOperation:(CHDBOperation *)operation toModel:(CHModel *)model {
    if ([operation isKindOfClass:[CHDBListOperation class]]) {
        CHDBListOperation *listOperation = (CHDBListOperation *)operation;
        NSArray *originalList = [model objectForKey:listOperation.listKey];
        NSMutableArray *list = [originalList mutableCopy] ?: [[NSMutableArray alloc] init];
        [list removeObject:listOperation.memberPK];
        if (listOperation.type != CHDBOperationTypeDelete) {
            NSInteger index = MIN_MAX(listOperation.memberIndex, 0, list.count);
            [list insertObject:listOperation.memberPK atIndex:index];
        }
        [model setObject:[list copy] forKey:listOperation.listKey];
        
    } else {
        CHDBModelOperation *modelOperation = (CHDBModelOperation *)operation;
        if (operation.type == CHDBOperationTypeDelete) {
            [model setObject:@(YES) forKey:@"deleted"];
        } else {
            [modelOperation.info enumerateKeysAndObjectsUsingBlock:
             ^(NSString *key, id object, BOOL *stop) {
                 [model setObject:object forKey:key];
             }];
        }
    }
}


#pragma mark -
#pragma mark Remote

+ (void)saveRemoteStory:(CHStory *)story {
    [self saveRemoteModel:story collection:kStoriesCollectionKey];
}

+ (void)saveRemoteBit:(CHBit *)bit {
    NSString *collection = [self collectionKeyForBitsForStoryPK:bit.storyPK];
    [self saveRemoteModel:bit collection:collection];
}

+ (void)saveRemoteModel:(CHModel *)model collection:(NSString *)collection {
    [[self writeConnection] readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        NSArray *operations = [self collectAllDatabaseOperationsWithTransaction:transaction];
        if (model.deleted) {
            [transaction removeObjectForKey:model.pk inCollection:collection];
            for (CHDBOperation *operation in operations) {
                if ([operation.entityPK isEqualToString:model.pk]) {
                    [transaction removeObjectForKey:operation.pk inCollection:kOperationsCollectionKey];
                }
            }
            
        } else {
            for (CHDBOperation *operation in operations) {
                if ([operation.entityPK isEqualToString:model.pk]) {
                    [self applyDatabaseOperation:operation toModel:model];
                }
            }
            [transaction setObject:model forKey:model.pk inCollection:collection];
        }
    }];
}


#pragma mark -
#pragma mark Dependents

+ (NSMutableDictionary *)viewDependentsMap {
    static NSMutableDictionary *viewDependentsMap;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        viewDependentsMap = [[NSMutableDictionary alloc] init];
    });
    return viewDependentsMap;
}

+ (void)addDependent:(id)dependent
        forExtension:(YapDatabaseExtension *)extension
       extensionName:(NSString *)extensionName {
    
    NSAssert([NSThread isMainThread], @"Expected main thread");
    
    NSHashTable *dependents = [self.viewDependentsMap objectForKey:extensionName];
    if (!dependents) {
        dependents = [NSHashTable weakObjectsHashTable];
        [self.viewDependentsMap setObject:dependents forKey:extensionName];
    }
    
    [dependents addObject:dependent];
    
    if (dependents.count > 0) {
        [self.database registerExtension:extension withName:extensionName];
    }
}

+ (void)removeDependent:(id)dependent
      forExtensionNamed:(NSString *)extensionName {
    
    NSAssert([NSThread isMainThread], @"Expected main thread");
    
    NSHashTable *dependents = [self.viewDependentsMap objectForKey:extensionName];
    
    [dependents removeObject:dependent];
    
    if (dependents.count == 0) {
        [self.database unregisterExtensionWithName:extensionName];
    }
}

@end
