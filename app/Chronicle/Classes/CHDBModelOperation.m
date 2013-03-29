#import "CHDBModelOperation.h"

static NSString * const kInfoKey = @"info";

@interface CHDBModelOperation ()

@property (nonatomic, strong, readwrite) NSDictionary *info;

@end

@implementation CHDBModelOperation

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        self.info = [aDecoder decodeObjectForKey:kInfoKey];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    
    [aCoder encodeObject:self.info forKey:kInfoKey];
}

+ (instancetype)newOperationOfType:(CHDBOperationType)operationType
                        entityName:(NSString *)entityName
                    collectionName:(NSString *)collectionName
                          entityPK:(NSString *)entityPK
                              info:(NSDictionary *)info {

    CHDBModelOperation *operation = [[self alloc] _initWithType:operationType
                                                     entityName:entityName
                                                 collectionName:collectionName
                                                       entityPK:entityPK];
    
    operation.info = info;
    
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
            typeString = @"INSERT";
            break;
        case CHDBOperationTypeDelete:
            typeString = @"DELETE";
            break;
        case CHDBOperationTypeUpdate:
            typeString = @"UPDATE";
            break;
        default:
            typeString = @"INVALID";
            break;
    }
    
    return [NSString stringWithFormat:@"%@ %@ %@ %@ (%lu values)",
            [super description],
            typeString,
            self.entityName,
            [self abbreivatedPK:self.entityPK],
            (unsigned long)self.info.count];
}

@end
