#import <Foundation/Foundation.h>

@interface CHUploadOperation : NSObject<NSCoding>

@property (nonatomic, strong, readonly) NSString *pk;
@property (nonatomic, strong, readonly) NSDate *date;

@property (nonatomic, strong, readonly) NSString *entityPK;
@property (nonatomic, strong, readonly) NSString *localIdentifier;

+ (instancetype)newOperationWithEntityPK:(NSString *)entityPK
                         localIdentifier:(NSString *)localIdentifier;

@end
