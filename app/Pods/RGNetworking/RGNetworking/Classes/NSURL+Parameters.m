//  Copyright 2013-present Ryan Gomba. All rights reserved.

#import "NSURL+Parameters.h"

@implementation NSURL (Parameters)

- (NSURL *)URLByAppendingParameterString:(NSString *)parameterString {
    if (!parameterString) {
        return self;
    }
    NSString *urlString = self.absoluteString;
    NSString *urlFormat = [urlString rangeOfString:@"?"].location == NSNotFound ? @"?%@" : @"&%@";
    urlString = [urlString stringByAppendingFormat:urlFormat, parameterString];
    return [NSURL URLWithString:urlString];
}

@end
