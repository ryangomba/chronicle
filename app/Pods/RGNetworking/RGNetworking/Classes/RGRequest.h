//  Copyright 2013-present Ryan Gomba. All rights reserved.

#import "AFHTTPRequestOperation.h"
#import "RGRequestError.h"
#import "RGDataUpload.h"

@class RGRequest;
typedef void (^RGRequestResponseHandler)(RGRequest *completedRequest, NSData *responseData, RGRequestError *error);
typedef void (^RGRequestJSONResponseHandler)(RGRequest *completedRequest, id responseObject, RGRequestError *error);
typedef void (^RGRequestSuccessHandler)(NSDictionary *response);
typedef void (^RGRequestFailureHandler)(RGRequestError *error);

@interface RGRequest : AFHTTPRequestOperation

@property (nonatomic, copy) RGRequestSuccessHandler successHandler;
@property (nonatomic, copy) RGRequestFailureHandler failureHandler;
@property (nonatomic, strong) NSDictionary *userInfo;

- (void)addDependent:(id)observer withPriority:(NSOperationQueuePriority)priority;
- (void)removeDependent:(id)observer;

@end

@interface RGGetRequest : RGRequest
+ (RGRequest *)requestWithURL:(NSURL *)url parameterString:(NSString *)parameterString;
+ (RGRequest *)requestWithURL:(NSURL *)url parameters:(NSDictionary *)parameters;
@end

@interface RGPostRequest : RGRequest
+ (RGRequest *)requestWithURL:(NSURL *)url parameters:(NSDictionary *)parameters files:(NSDictionary *)files;
@end

@interface RGPatchRequest : RGPostRequest
+ (RGRequest *)requestWithURL:(NSURL *)url parameters:(NSDictionary *)parameters files:(NSDictionary *)files;
@end

@interface RGDeleteRequest : RGRequest
+ (RGRequest *)requestWithURL:(NSURL *)url parameters:(NSDictionary *)parameters;
@end

@interface RGRequest (ImageRequest)

- (void)notifySuccessWithData:(NSData *)data forURL:(NSURL *)url;
- (void)notifyFailureWithError:(NSError *)error forURL:(NSURL *)url;

@end

@protocol RGImageRequestDelegate <NSObject>

- (void)imageRequest:(RGRequest *)request
    didLoadImageData:(NSData *)imageData
              forURL:(NSURL *)url;

- (void)imageRequest:(RGRequest *)request
    didFailWithError:(NSError *)error
              forURL:(NSURL *)url;

@end
