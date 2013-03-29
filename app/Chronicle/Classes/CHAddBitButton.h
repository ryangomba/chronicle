#import <UIKit/UIKit.h>

@class CHAddBitButton;
@protocol CHAddBitButtonDelegate <NSObject>

- (void)addBitButton:(CHAddBitButton *)button;

@end

@interface CHAddBitButton : UIView

@property (nonatomic, weak) id<CHAddBitButtonDelegate> delegate;

+ (CGSize)size;

@end
