//  Copyright 2013-present Ryan Gomba. All rights reserved.

@interface RGRequestError : NSError

@property (nonatomic, readonly) NSInteger statusCode;

+ (RGRequestError *)errorWithError:(NSError *)error statusCode:(NSInteger)statusCode;
+ (RGRequestError *)errorWithStatusCode:(NSInteger)statusCode message:(NSString *)message;

@end
