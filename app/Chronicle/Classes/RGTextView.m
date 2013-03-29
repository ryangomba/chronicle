#import "RGTextView.h"
#import <RGFoundation/RGFoundation.h>
#import <RGInterfaceKit/RGInterfaceKit.h>

#define kTextOffset 5.0

@interface RGTextView () {
    RGKVOHandle *_textObserver;
}

@property (nonatomic, strong) UILabel *placeholderLabel;

@end


@implementation RGTextView

#pragma mark -
#pragma mark NSObject

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        CGFloat vInset = -[self.class verticalInsetFix];
        [self setContentInset:UIEdgeInsetsMake(vInset, -kTextOffset, vInset, 0.0)];
        [self setClipsToBounds:NO];
        
        [self.placeholderLabel setX:kTextOffset];
        [self addSubview:self.placeholderLabel];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                selector:@selector(onTextChange)
                    name:UITextViewTextDidChangeNotification
                  object:self];
    }
    return self;
}


#pragma mark -
#pragma mark Class Methods

+ (CGFloat)verticalInsetFix {
    return 6.0;
}


#pragma mark -
#pragma mark Private Properties

- (UILabel *)placeholderLabel {
    if (!_placeholderLabel) {
        _placeholderLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _placeholderLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    }
    return _placeholderLabel;
}


#pragma mark -
#pragma mark Overrides

- (void)setAttributedText:(NSAttributedString *)attributedText {
    [super setAttributedText:attributedText];
    
    [self onTextChange];
}

- (void)setText:(NSString *)text {
    [super setText:text];
    
    [self onTextChange];
}


#pragma mark -
#pragma mark Notification Listeners

- (void)onTextChange {
    [self.placeholderLabel setHidden:self.hasText];
}


#pragma mark -
#pragma mark Public Properties

- (NSAttributedString *)placeholder {
    return self.placeholderLabel.attributedText;
}

- (void)setPlaceholder:(NSAttributedString *)placeholder {
    [self.placeholderLabel setAttributedText:placeholder];
}

@end
