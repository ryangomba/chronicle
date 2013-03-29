//  Copyright (c) 2013 Ryan Gomba. All rights reserved.

#define ALPHA_COLOR(rgbValue, alphaValue) \
    [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16)) / 255.0 \
                    green:((float)((rgbValue & 0xFF00) >> 8)) / 255.0 \
                     blue:((float)(rgbValue & 0xFF)) / 255.0 \
                    alpha:alphaValue]

#define HEX_COLOR(rgbValue) ALPHA_COLOR(rgbValue, 1.0)

#define WHITE_COLOR(alphaValue) [UIColor colorWithWhite:1.0f alpha:alphaValue]
#define BLACK_COLOR(alphaValue) [UIColor colorWithWhite:0.0f alpha:alphaValue]
