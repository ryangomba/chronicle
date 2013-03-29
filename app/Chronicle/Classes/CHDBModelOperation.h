#import "CHDBOperation.h"
#import "CHDBOperation.h"

@interface CHDBModelOperation : CHDBOperation

@property (nonatomic, strong, readonly) NSDictionary *info;

+ (instancetype)newOperationOfType:(CHDBOperationType)operationType
                        entityName:(NSString *)entityName
                    collectionName:(NSString *)collectionName
                          entityPK:(NSString *)entityPK
                              info:(NSDictionary *)info;

@end
