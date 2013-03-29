#import <Foundation/Foundation.h>
#import "CHUploadOperation.h"

static NSString * const kPKKey = @"pk";
static NSString * const kEntityPKKey = @"entityPK";
static NSString * const kLocalIdentifierKey = @"localIdentifier";
static NSString * const kDateKey = @"date";

@interface CHUploadOperation ()

@property (nonatomic, strong, readwrite) NSString *pk;
@property (nonatomic, strong, readwrite) NSString *entityPK;
@property (nonatomic, strong, readwrite) NSString *localIdentifier;
@property (nonatomic, strong, readwrite) NSDate *date;

@end

@implementation CHUploadOperation

+ (instancetype)newOperationWithEntityPK:(NSString *)entityPK
                         localIdentifier:(NSString *)localIdentifier {
    
    CHUploadOperation *operation = [[self alloc] init];
    operation.pk = [NSUUID UUID].UUIDString;
    operation.date = [NSDate date];
    operation.entityPK = entityPK;
    operation.localIdentifier = localIdentifier;
    return operation;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        self.pk = [aDecoder decodeObjectForKey:kPKKey] ?: [NSUUID UUID].UUIDString;
        self.entityPK = [aDecoder decodeObjectForKey:kEntityPKKey];
        self.localIdentifier = [aDecoder decodeObjectForKey:kLocalIdentifierKey];
        self.date = [aDecoder decodeObjectForKey:kDateKey] ?: [NSDate distantPast];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.pk forKey:kPKKey];
    [aCoder encodeObject:self.entityPK forKey:kEntityPKKey];
    [aCoder encodeObject:self.localIdentifier forKey:kLocalIdentifierKey];
    [aCoder encodeObject:self.date forKey:kDateKey];
}

@end
