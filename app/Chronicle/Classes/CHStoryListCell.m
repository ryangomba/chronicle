#import "CHStoryListCell.h"
#import "CHConstants.h"
#import "CHPhotoView.h"
#import "CHDatabase.h"
#import "CHPhoto.h"

#define kTitlePadding 20.0

@interface CHStoryListCell ()

@property (nonatomic, strong) CHPhotoView *photoView;
@property (nonatomic, strong) UIView *overlayView;

@property (nonatomic, strong) UILabel *titleLabel;

@end


@implementation CHStoryListCell

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setClipsToBounds:YES];
        
        [self.photoView setFrame:self.contentView.bounds];
        [self.contentView addSubview:self.photoView];
        
        [self.overlayView setFrame:self.contentView.bounds];
        [self.contentView addSubview:self.overlayView];
        
        [self.contentView addSubview:self.titleLabel];
    }
    return self;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        _titleLabel.numberOfLines = 2;
        
        [_titleLabel.layer setShadowColor:[UIColor blackColor].CGColor];
        [_titleLabel.layer setShadowOffset:CGSizeZero];
        [_titleLabel.layer setShadowOpacity:0.5];
        [_titleLabel.layer setShadowRadius:0.5];
    }
    return _titleLabel;
}

- (CHPhotoView *)photoView {
    if (!_photoView) {
        _photoView = [[CHPhotoView alloc] initWithFrame:CGRectZero];
        [_photoView setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
        [_photoView setContentMode:UIViewContentModeScaleAspectFill];
    }
    return _photoView;
}

- (UIView *)overlayView {
    if (!_overlayView) {
        _overlayView = [[UIView alloc] initWithFrame:CGRectZero];
        [_overlayView setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
        [_overlayView setBackgroundColor:HEX_COLOR(0x222222)];
        [_overlayView setAlpha:0.7];
    }
    return _overlayView;
}

- (NSDictionary *)titleAttributes {
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
//    paragraphStyle.alignment = NSTextAlignmentCenter;
    paragraphStyle.lineSpacing = 4.0;
    
    NSDictionary *attributes = @{
        NSFontAttributeName: [UIFont systemFontOfSize:20.0 weight:UIFontWeightBold],
        NSForegroundColorAttributeName: [UIColor whiteColor],
        NSParagraphStyleAttributeName: paragraphStyle,
    };
    
    return attributes;
}

- (void)setStory:(CHStory *)story {
    _story = story;
    
    // TODO this is less than optimal
    [self.photoView setPhoto:nil desiredImageSize:CHPhotoImageSizeSmall];
    [CHDatabase fetchAllBitsForStory:self.story completion:^(NSArray *bits) {
        CHPhotoBit *representativePhotoBit = nil;
        CHTextBit *representativeTextBit = nil;
        
        for (CHBit *bit in bits) {
            if (bit.type == CHBitTypePhoto) {
                if (!representativePhotoBit) {
                    representativePhotoBit = (CHPhotoBit *)bit;
                }
            } else if (bit.type == CHBitTypeText) {
                if (!representativeTextBit) {
                    representativeTextBit = (CHTextBit *)bit;
                }
            }
        }
        
        [self.photoView setPhoto:representativePhotoBit desiredImageSize:CHPhotoImageSizeSmall];
        
        if (representativeTextBit) {
            NSAttributedString *attributedString =
            [[NSAttributedString alloc] initWithString:representativeTextBit.text attributes:[self titleAttributes]];
            [self.titleLabel setAttributedText:attributedString];
        } else {
            [self.titleLabel setAttributedText:nil];
        }
        [self.titleLabel sizeToFit];
        [self setNeedsLayout];
    }];
}

- (void)layoutSubviews {
    [super layoutSubviews];

    self.titleLabel.frame = CGRectInset(self.bounds, kTitlePadding, kTitlePadding);
    
//    CGFloat titleLabelWidth = self.bounds.size.width - 2 * kTitlePadding;
//    CGFloat titleLabelY = self.bounds.size.height - self.titleLabel.bounds.size.height - kTitlePadding;
//    self.titleLabel.frame = CGRectMake(kTitlePadding, titleLabelY, titleLabelWidth, self.titleLabel.bounds.size.height);
}

@end
