#import "CHModel.h"

typedef NS_ENUM(NSInteger, CHBitType) {
    CHBitTypeUnspecified    = 0,
    CHBitTypePhoto          = 1,
    CHBitTypeVideo          = 2,
    CHBitTypeText           = 3,
};

@interface CHBit : CHModel

@property (nonatomic, assign) CHBitType type;
@property (nonatomic, copy) NSString *storyPK;

@end
