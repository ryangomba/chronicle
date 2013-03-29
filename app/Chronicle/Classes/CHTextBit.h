#import "CHBit.h"

typedef NS_ENUM(NSInteger, CHTextBitTextType) {
    CHTextBitTextTypeTitle,
    CHTextBitTextTypeParagraph,
};

@interface CHTextBit : CHBit

@property (nonatomic, strong) NSString *text;
@property (nonatomic, assign) CHTextBitTextType textType;

+ (instancetype)newTextBitOfType:(CHTextBitTextType)textType
                        withText:(NSString *)text
                         storyPK:(NSString *)storyPK;

@end
