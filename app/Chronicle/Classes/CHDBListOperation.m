#import "CHDBListOperation.h"

static NSString * const kListKeyKey = @"listKey";
static NSString * const kMemberPKKey = @"memberPK";
static NSString * const kMemberIndexKey = @"memberIndex";

@interface CHDBListOperation ()

@property (nonatomic, strong, readwrite) NSString *listKey;
@property (nonatomic, strong, readwrite) NSString *memberPK;
@property (nonatomic, assign, readwrite) NSInteger memberIndex;

@end

@implementation CHDBListOperation

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        self.listKey = [aDecoder decodeObjectForKey:kListKeyKey];
        self.memberPK = [aDecoder decodeObjectForKey:kMemberPKKey];
        self.memberIndex = [[aDecoder decodeObjectForKey:kMemberIndexKey] integerValue];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];

    [aCoder encodeObject:self.listKey forKey:kListKeyKey];
    [aCoder encodeObject:self.memberPK forKey:kMemberPKKey];
    [aCoder encodeObject:@(self.memberIndex) forKey:kMemberIndexKey];
}

+ (instancetype)newOperationOfType:(CHDBOperationType)operationType
                        entityName:(NSString *)entityName
                    collectionName:(NSString *)collectionName
                          entityPK:(NSString *)entityPK
                           listKey:(NSString *)listKey
                          memberPK:(NSString *)memberPK
                       memberIndex:(NSUInteger)memberIndex {

    CHDBListOperation *operation = [[self alloc] _initWithType:operationType
                                                    entityName:entityName
                                                collectionName:collectionName
                                                      entityPK:entityPK];
    
    operation.listKey = listKey;
    operation.memberPK = memberPK;
    operation.memberIndex = memberIndex;
    
    return operation;
}


#pragma mark -
#pragma mark Description

- (NSString *)abbreivatedPK:(NSString *)pk {
    return [NSString stringWithFormat:@"%@", [pk substringFromIndex:pk.length - 5]];
}

- (NSString *)description {
    NSString *typeString = nil;
    switch (self.type) {
        case CHDBOperationTypeInsert:
            typeString = @"ADD";
            break;
        case CHDBOperationTypeDelete:
            typeString = @"REMOVE";
            break;
        case CHDBOperationTypeUpdate:
            typeString = @"MOVE";
            break;
        default:
            typeString = @"INVALID";
            break;
    }
    
    return [NSString stringWithFormat:@"%@ %@ %@ INDEX=%lu for %@ on %@ %@",
            [super description],
            typeString,
            [self abbreivatedPK:self.memberPK],
            (unsigned long)self.memberIndex,
            self.listKey,
            self.entityName,
            [self abbreivatedPK:self.entityPK]];
}

@end
