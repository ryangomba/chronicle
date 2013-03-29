#import <UIKit/UIKit.h>
#import "RGTransformableView.h"
#import "RGTextView.h"
#import "CHTextBit.h"

@class CHTransformableTextView;
@protocol CHTransformableTextViewDelegate <RGTransformableViewDelegate>

- (BOOL)textViewShouldBeginEditing:(CHTransformableTextView *)textView;

@optional
- (void)textViewDidBeginEditing:(CHTransformableTextView *)textView;
- (void)textView:(CHTransformableTextView *)textView didChangeText:(NSString *)text;
- (void)textView:(CHTransformableTextView *)textView didChangeDesiredHeight:(CGFloat)desiredHeight;
- (void)textViewDidChangeSelection:(CHTransformableTextView *)textView;
- (void)textView:(CHTransformableTextView *)textView didEndEditingWithText:(NSString *)text;

@end

@interface CHTransformableTextView : RGTransformableView

@property (nonatomic, strong) CHTextBit *bit;

@property (nonatomic, strong, readonly) RGTextView *textField;

@property (nonatomic, readonly) CGFloat desiredHeight;
@property (nonatomic, readonly) BOOL isEditing;

@property (nonatomic, weak) id<CHTransformableTextViewDelegate> delegate;

+ (CGFloat)heightForText:(NSString *)text width:(CGFloat)width type:(CHTextBitTextType)type;

@end
