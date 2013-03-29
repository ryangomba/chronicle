#import "CHModel.h"

static NSString * const kPKKey = @"pk";

@interface CHModel ()

+ (instancetype)newModelWithPK:(NSString *)pk;

- (id)objectForKey:(NSString *)key;
- (void)setObject:(id)object forKey:(NSString *)key;
- (void)updateWithDictionary:(NSDictionary *)dictionary;

@end
