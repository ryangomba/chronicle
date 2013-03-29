//  Copyright 2013-present Ryan Gomba. All rights reserved.

#import "RGService.h"

#import <RGCore/RGMacros.h>

#if IS_IOS
#import <AFNetworking/AFNetworkActivityIndicatorManager.h>
#endif

#define kMinRequestConcurrency 3
#define kMaxRequestConcurrency 5

@interface RGService ()

@property (nonatomic, strong, readwrite) AFHTTPRequestOperationManager *client;
@property (nonatomic, strong, readwrite) NSOperationQueue *jsonParsingQueue;

@end


@implementation RGService

#pragma mark -
#pragma mark NSObject

- (id)init {
    if (self = [super init]) {
        weakify(self);
        [self.client.reachabilityManager setReachabilityStatusChangeBlock:
         ^(AFNetworkReachabilityStatus status) {
             strongify(self);
             BOOL isWIFI = status == AFNetworkReachabilityStatusReachableViaWiFi;
             NSInteger concurrency = isWIFI ? kMaxRequestConcurrency : kMinRequestConcurrency;
             [self.client.operationQueue setMaxConcurrentOperationCount:concurrency];
         }];
        [self.client.reachabilityManager startMonitoring];
        
        #if IS_IOS
        [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
        #endif
    }
    return self;
}

+ (instancetype)sharedService {
    static RGService *sharedService;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedService = [[self alloc] init];
    });
    return sharedService;
}


#pragma mark -
#pragma mark Class Methods

+ (NSString *)baseDomain {
    return @"localhost:8000";
}

+ (NSURL *)baseURL {
    NSString *baseDomain = [self baseDomain];
    NSString *urlString = [NSString stringWithFormat:@"http://%@", baseDomain];
    return [NSURL URLWithString:urlString];
}


#pragma mark -
#pragma mark Properties

- (AFHTTPRequestOperationManager *)client {
    if (!_client) {
        NSURL *baseURL = [self.class baseURL];
        _client = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:baseURL];
        [_client.operationQueue setMaxConcurrentOperationCount:kMaxRequestConcurrency];
    }
    return _client;
}

- (NSOperationQueue *)jsonParsingQueue {
    if (!_jsonParsingQueue) {
        _jsonParsingQueue = [[NSOperationQueue alloc] init];
    }
    return _jsonParsingQueue;
}


#pragma mark -
#pragma mark Sending Requests

- (void)startRawRequest:(RGRequest *)request
        responseHandler:(RGRequestResponseHandler)responseHandler {
    
    [self startRawRequest:request
          responseHandler:responseHandler
                    queue:self.client.operationQueue];
}

- (void)startRawRequest:(RGRequest *)request
        responseHandler:(RGRequestResponseHandler)responseHandler
                  queue:(NSOperationQueue *)queue {
    
    [request setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        __unsafe_unretained RGRequest *completedRequest = (RGRequest *)operation;
        if (responseHandler) {
            responseHandler(completedRequest, responseObject, nil);
        }

    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        __unsafe_unretained RGRequest *completedRequest = (RGRequest *)operation;
        NSInteger statusCode = completedRequest.response.statusCode;
        RGRequestError *requestError = [RGRequestError errorWithError:error statusCode:statusCode];
        if (responseHandler) {
            responseHandler(completedRequest, operation.responseData, requestError);
        }
    }];

    [queue addOperation:request];
}

- (void)startJSONRequest:(RGRequest *)request
         responseHandler:(RGRequestJSONResponseHandler)responseHandler {
    
    return [self startJSONRequest:request
                  responseHandler:responseHandler
                            queue:self.client.operationQueue];
}

- (void)startJSONRequest:(RGRequest *)request
         responseHandler:(RGRequestJSONResponseHandler)responseHandler
                   queue:(NSOperationQueue *)queue {

    AFHTTPRequestOperationManager *client = [RGService sharedService].client;
    [request setResponseSerializer:client.responseSerializer];
    
    [self startRawRequest:request responseHandler:
     ^(RGRequest *completedRequest, id responseObject, RGRequestError *error) {
         if (responseHandler) {
             responseHandler(completedRequest, responseObject, error);
         }
     } queue:queue];
}

@end
