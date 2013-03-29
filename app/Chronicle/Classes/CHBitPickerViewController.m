#import "CHBitPickerViewController.h"
#import "CHConstants.h"
#import "CHHeaderView.h"
#import "CHTransformableTextView.h"
#import "CHMediaPickerViewController.h"

typedef NS_ENUM(NSInteger, CHComponentType) {
  CHComponentTypeText,
  CHComponentTypeTitle,
  CHComponentTypeCount,
};

@interface CHBitPickerViewController ()<CHMediaPickerViewControllerDelegate, CHTransformableTextViewDelegate>

@property (nonatomic, strong) CHHeaderView *headerView;
@property (nonatomic, strong) CHMediaPickerViewController *mediaPickerViewController;

@property (nonatomic, strong) UIView *otherBitsView;
@property (nonatomic, strong) CHTransformableTextView *titleView1;
@property (nonatomic, strong) CHTransformableTextView *titleView2;
@property (nonatomic, strong) CHTransformableTextView *textView1;
@property (nonatomic, strong) CHTransformableTextView *textView2;

@property (nonatomic, weak) RGTransformableView *draggedView;

@end


@implementation CHBitPickerViewController

+ (instancetype)sharedController {
    static id object;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        object = [[self alloc] init];
    });
    return object;
}

#pragma mark -
#pragma mark View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = HEX_COLOR(0x1B1B1B);

    [self.headerView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.view addSubview:self.headerView];
    [self.headerView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor].active = YES; // HACK
    [self.headerView.leftAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leftAnchor].active = YES;
    [self.headerView.rightAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.rightAnchor].active = YES;
    [self.headerView.heightAnchor constraintEqualToConstant:50].active = YES;

    CGFloat bitSize = self.view.bounds.size.width / 4.0;
    self.otherBitsView = [[UIView alloc] init];
    [self.otherBitsView setClipsToBounds:YES];
    [self.otherBitsView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.view addSubview:self.otherBitsView];
    [self.otherBitsView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor].active = YES;
    [self.otherBitsView.leftAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leftAnchor].active = YES;
    [self.otherBitsView.rightAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.rightAnchor].active = YES;
    [self.otherBitsView.heightAnchor constraintEqualToConstant:bitSize].active = YES;
    
    [self addChildViewController:self.photosViewController];
    [self.photosViewController.view setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.view addSubview:self.photosViewController.view];
    [self.photosViewController.view.topAnchor constraintEqualToAnchor:self.headerView.bottomAnchor].active = YES;
    [self.photosViewController.view.bottomAnchor constraintEqualToAnchor:self.otherBitsView.topAnchor].active = YES;
    [self.photosViewController.view.leftAnchor constraintEqualToAnchor:self.view.leftAnchor].active = YES;
    [self.photosViewController.view.rightAnchor constraintEqualToAnchor:self.view.rightAnchor].active = YES;
    [self.photosViewController didMoveToParentViewController:self];

    [self reloadOtherBitViews];
}

- (void)viewDidDisappear:(BOOL)animated {
    [self reloadOtherBitViews];
}

- (void)reloadOtherBitViews {
    CGFloat bitSize = self.view.bounds.size.width / 4.0;

    if (self.titleView1.superview != self.view) {
        self.titleView1 = [[CHTransformableTextView alloc] init];
        self.titleView1.tag = CHComponentTypeTitle;
        [self.titleView1 setDelegate:self];
        [self.titleView1 setDesiredSize:CGSizeMake(bitSize, bitSize)];
        [self.titleView1 setDesiredCenter:CGPointMake(bitSize / 2.0, bitSize / 2.0) inTargetView:self.otherBitsView];
        [self.titleView1 moveToDesiredPositionAnimated:NO];
    }

    if (self.titleView2.superview != self.view) {
        self.titleView2 = [[CHTransformableTextView alloc] init];
        self.titleView2.tag = CHComponentTypeTitle;
        [self.titleView2 setDelegate:self];
        [self.titleView2 setDesiredSize:CGSizeMake(bitSize, bitSize)];
        [self.titleView2 setDesiredCenter:CGPointMake((bitSize + 1) + bitSize / 2.0, bitSize / 2.0) inTargetView:self.otherBitsView];
        [self.titleView2 moveToDesiredPositionAnimated:NO];
    }

    if (self.textView1.superview != self.view) {
        self.textView1 = [[CHTransformableTextView alloc] init];
        self.textView1.tag = CHComponentTypeText;
        [self.textView1 setDelegate:self];
        [self.textView1 setDesiredSize:CGSizeMake(bitSize, bitSize)];
        [self.textView1 setDesiredCenter:CGPointMake((bitSize + 1) * 2 + bitSize / 2.0, bitSize / 2.0) inTargetView:self.otherBitsView];
        [self.textView1 moveToDesiredPositionAnimated:NO];
    }

    if (self.textView2.superview != self.view) {
        self.textView2 = [[CHTransformableTextView alloc] init];
        self.textView2.tag = CHComponentTypeText;
        [self.textView2 setDelegate:self];
        [self.textView2 setDesiredSize:CGSizeMake(bitSize, bitSize)];
        [self.textView2 setDesiredCenter:CGPointMake((bitSize + 1) * 3 + bitSize / 2.0, bitSize / 2.0) inTargetView:self.otherBitsView];
        [self.textView2 moveToDesiredPositionAnimated:NO];
    }
}

#pragma mark -
#pragma mark CHTransformableTextViewDelegate

- (BOOL)textViewShouldBeginEditing:(CHTransformableTextView *)textView {
    return NO;
}

#pragma mark -
#pragma mark RGTransformableViewDelegate
// TODO don't like this here

- (BOOL)transformableViewShouldReceieveLongPress:(RGTransformableView *)view {
    return YES;
}

- (void)transformableViewDidReceieveLongPress:(RGTransformableView *)view {
    self.draggedView = view;

    CHTextBitTextType textType;
    if (view.tag == CHComponentTypeTitle) {
        textType = CHTextBitTextTypeTitle;
    } else {
        textType = CHTextBitTextTypeParagraph;
    }

    [self.delegate bitPickerViewController:self
                 willBeginDraggingTextView:view
                                    ofType:textType];
}

- (BOOL)transformableViewShouldTranslateX:(RGTransformableView *)view {
    return view == self.draggedView;
}

- (BOOL)transformableViewShouldTranslateY:(RGTransformableView *)view {
    return view == self.draggedView;
}


#pragma mark -
#pragma mark Properties

- (CHHeaderView *)headerView {
    if (!_headerView) {
        _headerView = [[CHHeaderView alloc] init];
        [_headerView setTranslatesAutoresizingMaskIntoConstraints:NO];

        CGFloat headerHeight = 50;
        CGRect buttonRect = CGRectMake(0.0, 0.0, headerHeight, headerHeight);
        UIButton *backButton = [[UIButton alloc] initWithFrame:buttonRect];
        [backButton setImage:[UIImage imageNamed:@"back.png"] forState:UIControlStateNormal];
        [backButton addTarget:self action:@selector(onBackButtonTapped) forControlEvents:UIControlEventTouchUpInside];
        [_headerView setLeftBarView:backButton];
    }
    return _headerView;
}

- (CHMediaPickerViewController *)photosViewController {
    if (!_mediaPickerViewController) {
        _mediaPickerViewController = [[CHMediaPickerViewController alloc] init];
        _mediaPickerViewController.delegate = self;
    }
    return _mediaPickerViewController;
}

// actions

- (void)onBackButtonTapped {
    [self.delegate bitPickerDidDismiss:self];
}


#pragma mark -
#pragma mark CHMediaViewControllerDelegate

- (void)mediaPickerViewController:(CHMediaPickerViewController *)controller
            willBeginDraggingView:(RGTransformableView *)view
                         forPhoto:(CHPhoto *)photo {
    
    [self.delegate bitPickerViewController:self
                     willBeginDraggingView:view
                                  forPhoto:photo];
}

@end
