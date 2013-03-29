#define SCREEN_IS_RETINA ([UIScreen mainScreen].scale > 1.0)
#define SCREEN_IS_TALL ([UIScreen mainScreen].bounds.size.height > 480)

#define SAFE_DRAW_SIZE(size) (DEVICE_IS_RETINA ? size : roundf(size))

#define ALPHA_COLOR(rgbValue, alphaValue) \
    [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16)) / 255.0 \
                    green:((float)((rgbValue & 0xFF00) >> 8)) / 255.0 \
                     blue:((float)(rgbValue & 0xFF)) / 255.0 \
                    alpha:alphaValue]

#define HEX_COLOR(rgbValue) ALPHA_COLOR(rgbValue, 1.0)

#define WHITE_COLOR(alphaValue) [UIColor colorWithWhite:1.0f alpha:alphaValue]
#define BLACK_COLOR(alphaValue) [UIColor colorWithWhite:0.0f alpha:alphaValue]

#define NC [NSNotificationCenter defaultCenter]

#define IS_IPAD (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)

static CGFloat const kCHDefaultPadding = 20.0;
static CGFloat const kCHDefaultSpacing = 10.0;
static CGFloat const kCHAvatarSize = 56.0;
static CGFloat const kCHButtonSize = 44.0;
static CGFloat const kCHDefaultCellHeight = 54.0;
#define kCHTrayHeight (IS_IPAD ? 100.0 : 68.0)

#define kCHDefaultTextColor HEX_COLOR(0x444444)
#define kCHHighlightColor HEX_COLOR(0xe03b3e)
#define kCHBorderColor HEX_COLOR(0xdddddd)
#define kCHLightTextColor HEX_COLOR(0x888888)

// TEMP move out of here
static NSString * const kCHPhotosAddedNotificationKey = @"photo-added";
static NSString * const kCHAlbumAddedNotificationKey = @"album-added";

static NSString * const kCHSyncStartedKey = @"sync-started";
