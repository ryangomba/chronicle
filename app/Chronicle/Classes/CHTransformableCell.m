#import "CHTransformableCell.h"
#import <RGFoundation/RGFoundation.h>
#import <RGInterfaceKit/RGInterfaceKit.h>
#import "CHConstants.h"

static CGFloat const kItemSize = 60.0;

@interface CHTransformableCell ()

@property (nonatomic, strong) UIView *itemView;

@end

@implementation CHTransformableCell

- (void)dealloc {
    if (self.transformableView.targetView == self) {
        [self.transformableView removeFromViewHierarchy];
    }
}

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setClipsToBounds:YES];

        self.contentView.frame = CGRectInset(self.bounds, 0, 10);
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    
    // TODO do we need this? can steal away a view that is being dragged
//    if (self.transformableView.targetView == self.contentView) {
//        //        NSAssert(NO, @"Cell reused improperly");
//        [self.transformableView removeFromViewHierarchy];
//    }
//    [self setTransformableView:nil];
}

- (void)setAnimatingIn:(BOOL)animatingIn {
    _animatingIn = animatingIn;
    
    if (animatingIn) {
        CGRect itemRect = CGRectMake(0.0, 0.0, self.contentView.bounds.size.width, 0.0);
        self.itemView = [[UIView alloc] initWithFrame:itemRect];
        self.itemView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.itemView.backgroundColor = HEX_COLOR(0xeeeeee);
        self.itemView.layer.cornerRadius = 6.0;
        [self.contentView addSubview:self.itemView];
    } else {
        [self.itemView removeFromSuperview];
        self.itemView = nil;
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];

    self.contentView.frame = CGRectInset(self.bounds, 0, 10);
    
    [self.itemView setHeight:MIN(self.contentView.frameHeight, kItemSize)];
    self.itemView.center = CGRectGetMiddle(self.contentView.bounds);
    
    // HACK
    if ([self.transformableView respondsToSelector:@selector(isEditing)]) {
        BOOL isEditing = [(id)self.transformableView isEditing];
        if (isEditing) {
            [self.transformableView setDesiredSize:self.contentView.bounds.size];
            [self.transformableView setDesiredCenter:CGRectGetMiddle(self.contentView.frame) inTargetView:self.contentView];
            [self.transformableView moveToDesiredPositionAnimated:NO];
        }
    }
}

@end
