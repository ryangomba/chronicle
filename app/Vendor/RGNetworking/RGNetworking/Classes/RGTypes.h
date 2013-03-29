//  Copyright 2013-present Ryan Gomba. All rights reserved.

#if TARGET_OS_IPHONE

#define CGNSRect CGRect
#define UINSImage UIImage
#define UINSImageView UIImageView

#define SIZE_VALUE(size) [NSValue valueWithCGSize:size]

#else

#define CGNSRect NSRect
#define UINSImage NSImage
#define UINSImageView NSImageView

#define SIZE_VALUE(size) [NSValue valueWithSize:size]

#endif
