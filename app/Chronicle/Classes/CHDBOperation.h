#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, CHDBOperationType) {
    CHDBOperationTypeInvalid  = 0,
    CHDBOperationTypeInsert   = 1,
    CHDBOperationTypeUpdate   = 2,
    CHDBOperationTypeDelete   = 3,
};

@interface CHDBOperation : NSObject<NSCoding>

@property (nonatomic, strong, readonly) NSString *pk;

@property (nonatomic, assign, readonly) CHDBOperationType type;
@property (nonatomic, strong, readonly) NSDate *date;

@property (nonatomic, strong, readonly) NSString *entityName;
@property (nonatomic, strong, readonly) NSString *collectionName;
@property (nonatomic, strong, readonly) NSString *entityPK;

- (instancetype)_initWithType:(CHDBOperationType)operationType
                   entityName:(NSString *)entityName
               collectionName:(NSString *)collectionName
                     entityPK:(NSString *)entityPK;

@end
