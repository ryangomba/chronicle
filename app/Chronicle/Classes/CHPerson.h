#import "CHModel.h"

@interface CHPerson : CHModel

@property (nonatomic, strong) NSString *firstName;
@property (nonatomic, strong) NSString *fullName;

- (NSURL *)avatarURLForImageOfSize:(NSInteger)imageSize;

+ (instancetype)newPersonWithPK:(NSString *)pk
                      firstName:(NSString *)firstName
                       fullName:(NSString *)fullName;

@end
