//  Copyright 2013-present Ryan Gomba. All rights reserved.

#import "RGRequestError.h"

#define kStatusCodeKey @"status-code"

@implementation RGRequestError

+ (RGRequestError *)errorWithError:(NSError *)error statusCode:(NSInteger)statusCode {
    NSMutableDictionary *userInfo = [error.userInfo mutableCopy];
    [userInfo setObject:@(statusCode) forKey:kStatusCodeKey];

    return [RGRequestError errorWithDomain:@"server"
                                      code:NSURLErrorBadServerResponse
                                  userInfo:userInfo];
}

+ (RGRequestError *)errorWithStatusCode:(NSInteger)statusCode message:(NSString *)message {
    NSDictionary *userInfo = @{
        kStatusCodeKey: @(statusCode),
        NSLocalizedDescriptionKey: message ?: @"",
    };

    return [RGRequestError errorWithDomain:@"server"
                                      code:NSURLErrorBadServerResponse
                                  userInfo:userInfo];
}

- (NSInteger)statusCode {
    return [[self.userInfo objectForKey:kStatusCodeKey] intValue];
}

- (NSString *)description {
    NSString *message = [self.userInfo objectForKey:NSLocalizedDescriptionKey];
    return [NSString stringWithFormat:@"ERROR: (%ld) %@", (long)self.statusCode, message];
}

@end
