#import "CHTextBit.h"
#import "CHModel+Internal.h"

@implementation CHTextBit

@dynamic text;
@dynamic textType;

#pragma mark -
#pragma mark NSObject

+ (instancetype)newTextBitOfType:(CHTextBitTextType)textType
                        withText:(NSString *)text
                         storyPK:(NSString *)storyPK {
    
    CHTextBit *textBit = [self newModel];
    textBit.storyPK = storyPK;
    textBit.type = CHBitTypeText;
    textBit.text = text;
    textBit.textType = textType;
    return textBit;
}

@end
