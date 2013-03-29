#import "CHTransformableTextView.h"
#import "CHConstants.h"
#import "RGTextView.h"
#import <RGInterfaceKit/RGInterfaceKit.h>

@interface CHTransformableTextView ()<UITextViewDelegate>

@property (nonatomic, copy) NSString *placeholderText;

@property (nonatomic, readwrite) CGFloat desiredHeight;
@property (nonatomic, strong, readwrite) RGTextView *textField;

@end


@implementation CHTransformableTextView

@dynamic delegate;

#pragma mark -
#pragma mark NSObject

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self.contentView addSubview:self.textField];
        
        self.tapRecognizer.enabled = NO;
    }
    return self;
}


#pragma mark -
#pragma mark Properties

- (id)attachedModel {
    return self.bit;
}

- (void)setBit:(CHTextBit *)bit {
    _bit = bit;
    
    self.textField.placeholder = [self.class placeholderForType:self.bit.textType];
    
    [self setText:bit.text];
}

- (RGTextView *)textField {
    if (!_textField) {
        _textField = [[RGTextView alloc] initWithFrame:CGRectZero];
        [_textField setDelegate:self];
        
        _textField.scrollEnabled = NO;
        _textField.returnKeyType = UIReturnKeyDone;
        
        [self enableLongPressSelection:NO];
    }
    return _textField;
}

- (NSString *)text {
    return self.textField.attributedText.string;
}

- (void)setText:(NSString *)text {
    NSAttributedString *attributedString = [self.class attributedStringForString:text type:self.bit.textType];
    [self.textField setAttributedText:attributedString];
}

- (BOOL)isEditing {
    return self.textField.isFirstResponder;
}


#pragma mark -
#pragma mark Class Methods

+ (UIFont *)fontForType:(CHTextBitTextType)type {
    if (type == CHTextBitTextTypeTitle) {
        return [UIFont systemFontOfSize:36.0 weight:UIFontWeightBold];
    } else {
        return [UIFont systemFontOfSize:16.0];
    }
}

+ (NSAttributedString *)placeholderForType:(CHTextBitTextType)type {
    NSMutableDictionary *attributes = [[self attributesForTextType:type] mutableCopy];
    attributes[NSForegroundColorAttributeName] = HEX_COLOR(0xcccccc);
    
    NSString *placeholderString = nil;
    if (type == CHTextBitTextTypeTitle) {
        placeholderString = @"Title";
    } else {
        placeholderString = @"Write something...";
    }
    
    return [[NSAttributedString alloc] initWithString:placeholderString attributes:attributes];
}

+ (NSDictionary *)attributesForTextType:(CHTextBitTextType)type {
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
//    paragraphStyle.lineSpacing = 4.0;
//    paragraphStyle.paragraphSpacing = 16.0;
    paragraphStyle.lineSpacing = 8.0;
    paragraphStyle.paragraphSpacing = 14.0;
    
    NSDictionary *attributes = @{
                                 NSFontAttributeName: [self fontForType:type],
                                 NSForegroundColorAttributeName: HEX_COLOR(0x444444),
                                 NSParagraphStyleAttributeName: paragraphStyle,
                                 };
    
    return attributes;
}

+ (NSAttributedString *)attributedStringForString:(NSString *)string type:(CHTextBitTextType)type {
    NSDictionary *attributes = [self attributesForTextType:type];
    return [[NSAttributedString alloc] initWithString:string attributes:attributes];
}

+ (CGSize)sizeForText:(NSString *)text type:(CHTextBitTextType)type maxSize:(CGSize)maxSize {
    if (!text) {
        return CGSizeZero;
    }
    
    RGTextView *calculationView = [[RGTextView alloc] initWithFrame:CGRectZero];
    calculationView.attributedText = [self attributedStringForString:text type:type];
    CGSize desiredSize = [calculationView sizeThatFits:maxSize];
    desiredSize.height -= [RGTextView verticalInsetFix] * 2;
    return CGSizeMake(ceilf(desiredSize.width), ceilf(desiredSize.height));
}

+ (CGFloat)heightForText:(NSString *)text width:(CGFloat)width type:(CHTextBitTextType)type {
    if (text.length == 0) {
        text = [self placeholderForType:type].string;
    }
    
    CGSize maxLabelSize = CGSizeMake(width, CGFLOAT_MAX);
    CGFloat textHeight = [self sizeForText:text type:type maxSize:maxLabelSize].height;
    return textHeight;
}


#pragma mark -
#pragma mark Private

- (void)enableLongPressSelection:(BOOL)enable {
    for (UIGestureRecognizer *recognizer in self.textField.gestureRecognizers) {
        if ([recognizer isKindOfClass:[UILongPressGestureRecognizer class]]) {
            recognizer.enabled = enable;
        }
    }
}


#pragma mark -
#pragma mark UITextViewDelegate

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
    return [self.delegate textViewShouldBeginEditing:self];
}

- (void)textViewDidBeginEditing:(UITextView *)textView {
    [self enableLongPressSelection:YES];
    
    if ([self.delegate respondsToSelector:@selector(textViewDidBeginEditing:)]) {
        [self.delegate textViewDidBeginEditing:self];
    }
    
    self.textField.typingAttributes = [self.class attributesForTextType:self.bit.textType];
}

- (void)textViewDidChange:(UITextView *)textView {
    if ([self.delegate respondsToSelector:@selector(textView:didChangeText:)]) {
        [self.delegate textView:self didChangeText:self.text];
    }
    
    CGFloat desiredHeight = [self.class heightForText:self.text
                                                width:self.contentView.frameWidth
                                                 type:self.bit.textType];
    
    if (self.desiredHeight != desiredHeight) {
        [self setDesiredHeight:desiredHeight];
        
        if ([self.delegate respondsToSelector:@selector(textView:didChangeDesiredHeight:)]) {
            [self.delegate textView:self didChangeDesiredHeight:desiredHeight];
        }
    }
}

- (void)textViewDidChangeSelection:(UITextView *)textView {
    if ([self.delegate respondsToSelector:@selector(textViewDidChangeSelection:)]) {
        [self.delegate textViewDidChangeSelection:self];
    }
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if ([text isEqualToString:@"\n"]) {
        [textView resignFirstResponder];
        return NO;
    }
    return YES;
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    if ([self.delegate respondsToSelector:@selector(textView:didEndEditingWithText:)]) {
        [self.delegate textView:self didEndEditingWithText:self.text];
    }
    
    [self enableLongPressSelection:NO];
}


#pragma mark -
#pragma mark Overrides

- (void)notifyDelegateWillBeginUserInteraction {
    [super notifyDelegateWillBeginUserInteraction];
    
    self.textField.editable = NO;
}

- (void)notifyDelegateWillFinishUserInteraction {
    [super notifyDelegateWillFinishUserInteraction];

    self.textField.editable = YES;
}


#pragma mark -
#pragma mark Layout

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGRect textFieldRect = self.bounds;
    textFieldRect.size.height += [RGTextView verticalInsetFix] * 2;
    [self.textField setFrame:textFieldRect];
}

@end
