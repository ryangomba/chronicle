#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "NSObject+Blocks.h"
#import "NSObject+KVO.h"
#import "NSSet+Additions.h"
#import "RGFoundation.h"
#import "RGGeometry.h"

FOUNDATION_EXPORT double RGFoundationVersionNumber;
FOUNDATION_EXPORT const unsigned char RGFoundationVersionString[];

