#import "CHDBModelOperation.h"
#import "CHUploadOperation.h"
#import "CHDBOperation.h"
#import "CHPerson.h"
#import "CHStory.h"
#import "CHBit.h"
#import "CHTextBit.h"
#import "CHPhotoBit.h"
#import "CHDBOperation.h"

@class YapDatabase;
@class YapDatabaseExtension;

static NSString * const kCHNotificationBitModifiedExternally = @"bit-modified-externally";

@interface CHDatabase : NSObject

+ (YapDatabase *)database;

// fetches

+ (void)fetchAllPeopleWithCompletion:(void (^)(NSArray *friends))completion;
+ (void)fetchAllStoriesWithCompletion:(void (^)(NSArray *stories))completion;

+ (void)fetchAllBitsForStory:(CHStory *)story completion:(void (^)(NSArray *bits))completion;
+ (void)fetchAllPeopleForStory:(CHStory *)story completion:(void (^)(NSArray *people))completion;

+ (void)fetchAllBitsWithLocalIdentifier:(NSString *)localIdentifier completion:(void (^)(NSArray *bits))completion;

// stories

+ (void)addStory:(CHStory *)story;
+ (void)deleteStory:(CHStory *)story;

// bits

+ (void)changeText:(NSString *)text forBit:(CHTextBit *)bit;

+ (void)insertBit:(CHBit *)bit atIndex:(NSInteger)index story:(CHStory *)story;
+ (void)moveBit:(CHBit *)bit toIndex:(NSInteger)toIndex story:(CHStory *)story;
+ (void)removeBit:(CHBit *)bit story:(CHStory *)story;

// TODO don't like these params passed; could result in incorrect aspectRatio for period of tine
+ (void)updateMediaForBit:(CHPhotoBit *)bit
           newAspectRatio:(CGFloat)newAspectRatio
 newMediaModificationDate:(NSDate *)newMediaModificationDate;

// people

+ (void)addPeople:(NSArray *)people;

+ (void)addPerson:(CHPerson *)person story:(CHStory *)story;
+ (void)removePerson:(CHPerson *)person story:(CHStory *)story;

// operations

+ (void)fetchAllDatabaseOperationsWithCompletion:(void (^)(NSArray *operations))completion;
+ (void)enqueueDatabaseOperation:(CHDBOperation *)databaseOperation;
+ (void)deleteDatabaseOperation:(CHDBOperation *)databaseOperation;

// uploads

+ (void)fetchAllUploadOperationsWithCompletion:(void (^)(NSArray *operations))completion;
+ (void)enqueueUploadOperation:(CHUploadOperation *)uploadOperation;
+ (void)deleteUploadOperation:(CHUploadOperation *)uploadOperation;

// cloud

+ (void)saveRemoteStory:(CHStory *)story;
+ (void)saveRemoteBit:(CHBit *)bit;

@end
