#import <Foundation/Foundation.h>

@interface CHModel : NSObject<NSCoding>

@property (nonatomic, copy, readonly) NSString *pk;
@property (nonatomic, assign, readonly) BOOL deleted;

+ (instancetype)newModel;

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;
- (NSDictionary *)dictionaryRepresentation;

@end
