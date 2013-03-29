#import "CHDBOperation.h"

static NSString * const kPKKey = @"pk";
static NSString * const kTypeKey = @"type";
static NSString * const kDateKey = @"date";
static NSString * const kEntityNameKey = @"entityName";
static NSString * const kCollectionNameKey = @"collectionName";
static NSString * const kEntityPKKey = @"entityPK";

@interface CHDBOperation ()

@property (nonatomic, strong, readwrite) NSString *pk;

@property (nonatomic, assign, readwrite) CHDBOperationType type;
@property (nonatomic, strong, readwrite) NSDate *date;

@property (nonatomic, strong, readwrite) NSString *entityName;
@property (nonatomic, strong, readwrite) NSString *collectionName;
@property (nonatomic, strong, readwrite) NSString *entityPK;

@end

@implementation CHDBOperation

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        self.pk = [aDecoder decodeObjectForKey:kPKKey];
        self.type = [[aDecoder decodeObjectForKey:kTypeKey] integerValue];
        self.date = [aDecoder decodeObjectForKey:kDateKey];
        self.entityName = [aDecoder decodeObjectForKey:kEntityNameKey];
        self.collectionName = [aDecoder decodeObjectForKey:kCollectionNameKey];
        self.entityPK = [aDecoder decodeObjectForKey:kEntityPKKey];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.pk forKey:kPKKey];
    [aCoder encodeObject:@(self.type) forKey:kTypeKey];
    [aCoder encodeObject:self.date forKey:kDateKey];
    [aCoder encodeObject:self.entityName forKey:kEntityNameKey];
    [aCoder encodeObject:self.collectionName forKey:kCollectionNameKey];
    [aCoder encodeObject:self.entityPK forKey:kEntityPKKey];
}

- (instancetype)_initWithType:(CHDBOperationType)operationType
                   entityName:(NSString *)entityName
               collectionName:(NSString *)collectionName
                     entityPK:(NSString *)entityPK {

    if (self = [super init]) {
        self.pk = [NSUUID UUID].UUIDString;
        self.type = operationType;
        self.date = [NSDate date];
        self.entityName = entityName;
        self.collectionName = collectionName;
        self.entityPK = entityPK;
    }
    return self;
}

@end
