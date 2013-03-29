//  Copyright 2013-present Ryan Gomba. All rights reserved.

#import <AFNetworking/AFNetworking.h>

#import "RGRequest.h"

@interface RGService : NSObject

+ (instancetype)sharedService;

@property (nonatomic, strong, readonly) AFHTTPRequestOperationManager *client;

- (void)startRawRequest:(RGRequest *)request
        responseHandler:(RGRequestResponseHandler)responseHandler;

- (void)startRawRequest:(RGRequest *)request
        responseHandler:(RGRequestResponseHandler)responseHandler
                  queue:(NSOperationQueue *)queue;

- (void)startJSONRequest:(RGRequest *)request
         responseHandler:(RGRequestJSONResponseHandler)responseHandler;

- (void)startJSONRequest:(RGRequest *)request
         responseHandler:(RGRequestJSONResponseHandler)responseHandler
                   queue:(NSOperationQueue *)queue;

@end
