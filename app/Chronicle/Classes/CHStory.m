#import "CHStory.h"
#import "CHModel+Internal.h"

@implementation CHStory

@dynamic date;
@dynamic bitPKs;
@dynamic peoplePKs;

#pragma mark -
#pragma mark Constructors

+ (instancetype)newStory {
    CHStory *story = [CHStory newModel];
    story.date = [NSDate date];
    return story;
}

@end
