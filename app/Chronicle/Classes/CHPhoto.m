#import "CHPhoto.h"

@implementation CHPhoto

#pragma mark -
#pragma mark Derived

- (NSString *)day {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"dd MMM YYYY"];
    return [formatter stringFromDate:self.creationDate];
}

@end
