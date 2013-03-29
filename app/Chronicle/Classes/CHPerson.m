#import "CHPerson.h"

#import "CHModel+Internal.h"

@implementation CHPerson

@dynamic firstName;
@dynamic fullName;

#pragma mark -
#pragma mark Constructors

+ (instancetype)newPersonWithPK:(NSString *)pk
                      firstName:(NSString *)firstName
                       fullName:(NSString *)fullName {
    
    CHPerson *person = [CHPerson newModelWithPK:pk];
    person.firstName = firstName;
    person.fullName = fullName;
    return person;
}


#pragma mark -
#pragma mark Public

- (NSURL *)avatarURLForImageOfSize:(NSInteger)imageSize {
    // TODO: re-implement
    return [NSURL URLWithString:@"foo.bar"];
}

@end
