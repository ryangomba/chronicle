// Copyright 2014-present Ryan Gomba. All Rights Reserved.

FOUNDATION_EXTERN CGPoint CGPointOffset(CGPoint point1, CGPoint point2);
FOUNDATION_EXTERN CGPoint CGPointOffsetX(CGPoint point, CGFloat x);
FOUNDATION_EXTERN CGPoint CGPointOffsetY(CGPoint point, CGFloat y);

FOUNDATION_EXTERN CGSize CGSizeMultiply(CGSize size, CGFloat scale);

FOUNDATION_EXTERN CGPoint CGRectGetMidPoint(CGRect rect);
FOUNDATION_EXTERN CGPoint CGRectGetMiddle(CGRect rect);

FOUNDATION_EXTERN CGSize RGSizeOuterSizeWithAspectRatio(CGSize size, CGFloat aspectRatio);
FOUNDATION_EXTERN CGSize RGSizeInnerSizeWithAspectRatio(CGSize size, CGFloat aspectRatio);

FOUNDATION_EXTERN CGRect RGRectOuterRectWithAspectRatio(CGRect rect, CGFloat aspectRatio);
FOUNDATION_EXTERN CGRect RGRectInnerRectWithAspectRatio(CGRect rect, CGFloat aspectRatio);
