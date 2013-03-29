#import "CHDBOperation.h"

@interface CHDBListOperation : CHDBOperation

@property (nonatomic, strong, readonly) NSString *listKey;
@property (nonatomic, strong, readonly) NSString *memberPK;
@property (nonatomic, assign, readonly) NSInteger memberIndex;

+ (instancetype)newOperationOfType:(CHDBOperationType)operationType
                        entityName:(NSString *)entityName
                    collectionName:(NSString *)collectionName
                          entityPK:(NSString *)entityPK
                           listKey:(NSString *)listKey
                          memberPK:(NSString *)memberPK
                       memberIndex:(NSUInteger)memberIndex;

@end
