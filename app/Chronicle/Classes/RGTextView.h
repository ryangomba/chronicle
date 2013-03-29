#import <UIKit/UIKit.h>

@interface RGTextView : UITextView

@property (nonatomic, strong) NSAttributedString *placeholder;

+ (CGFloat)verticalInsetFix;

@end
