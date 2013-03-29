// Copyright 2014-present Ryan Gomba. All Rights Reserved.

#import "RGGeometry.h"

CGPoint CGPointOffset(CGPoint point1, CGPoint point2) {
    return CGPointMake(point1.x + point2.x, point1.y + point2.y);
}

CGPoint CGPointOffsetX(CGPoint point, CGFloat x) {
    return CGPointMake(point.x + x, point.y);
}

CGPoint CGPointOffsetY(CGPoint point, CGFloat y) {
    return CGPointMake(point.x, point.y + y);
}

CGSize CGSizeMultiply(CGSize size, CGFloat scale) {
    return CGSizeMake(size.width * scale, size.height * scale);
}

CGPoint CGRectGetMidPoint(CGRect rect) {
    return CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));
}

CGPoint CGRectGetMiddle(CGRect rect) {
    return CGPointMake(rect.size.width / 2, rect.size.height / 2);
}

CGSize RGSizeOuterSizeWithAspectRatio(CGSize size, CGFloat aspectRatio) {
    CGFloat targetAspect = size.width / size.height;
    if (aspectRatio == targetAspect) {
        return size;
    }
    
    if (aspectRatio < targetAspect) {
        return CGSizeMake(size.width, size.width / aspectRatio);
    } else {
        return CGSizeMake(size.height * aspectRatio, size.height);
    }
}

CGSize RGSizeInnerSizeWithAspectRatio(CGSize size, CGFloat aspectRatio) {
    CGFloat targetAspect = size.width / size.height;
    if (aspectRatio == targetAspect) {
        return size;
    }
    
    if (aspectRatio > targetAspect) {
        return CGSizeMake(size.width, size.width / aspectRatio);
    } else {
        return CGSizeMake(size.height, size.height * aspectRatio);
    }
}

CGRect RGRectOuterRectWithAspectRatio(CGRect rect, CGFloat aspectRatio) {
    CGSize newSize = RGSizeOuterSizeWithAspectRatio(rect.size, aspectRatio);
    
    CGRect outputRect = CGRectZero;
    outputRect.size = newSize;
    outputRect.origin.x = rect.origin.x - (CGFloat)floor((outputRect.size.width - rect.size.width) / 2.0);
    outputRect.origin.y = rect.origin.y - (CGFloat)floor((outputRect.size.height - rect.size.height) / 2.0);
    
    return outputRect;
}

CGRect RGRectInnerRectWithAspectRatio(CGRect rect, CGFloat aspectRatio) {
    CGSize newSize = RGSizeInnerSizeWithAspectRatio(rect.size, aspectRatio);
    
    CGRect outputRect = CGRectZero;
    outputRect.size = newSize;
    outputRect.origin.x = rect.origin.x - (CGFloat)floor((outputRect.size.width - rect.size.width) / 2.0);
    outputRect.origin.y = rect.origin.y - (CGFloat)floor((outputRect.size.height - rect.size.height) / 2.0);
    
    return outputRect;
}
