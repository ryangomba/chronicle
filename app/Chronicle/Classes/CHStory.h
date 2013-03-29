#import "CHModel.h"

@interface CHStory : CHModel

@property (nonatomic, strong) NSDate *date;
@property (nonatomic, strong) NSArray *bitPKs;
@property (nonatomic, strong) NSSet *peoplePKs;

+ (instancetype)newStory;

@end
