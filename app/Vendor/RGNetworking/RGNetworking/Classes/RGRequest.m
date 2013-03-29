//  Copyright 2013-present Ryan Gomba. All rights reserved.

#import "RGRequest.h"

#import <RGCore/RGAssert.h>

#import "RGService.h"
#import "NSURL+Parameters.h"

#define kDefaultDownloadRequestTimeoutInterval 10.0f
#define kDefaultUploadRequestTimeoutInterval 60.0f
#define kPriorityKey @"priority"

@interface RGRequest() {
    NSHashTable *_dependents;
}

@end


@implementation RGRequest

- (instancetype)initWithRequest:(NSURLRequest *)urlRequest {
    if (self = [super initWithRequest:urlRequest]) {
        _dependents = [NSHashTable weakObjectsHashTable];
    }
    return self;
}

+ (RGRequest *)requestFromURLRequest:(NSMutableURLRequest *)urlRequest {
    return [self requestFromURLRequest:urlRequest
                       timeoutInterval:kDefaultDownloadRequestTimeoutInterval];
}

+ (RGRequest *)requestFromURLRequest:(NSMutableURLRequest *)urlRequest
                     timeoutInterval:(NSTimeInterval)timeoutInterval {
    
    [urlRequest setTimeoutInterval:timeoutInterval];

    // Caching is handled by RGCache
    [urlRequest setCachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData];
    
    RGRequest *request = [[RGRequest alloc] initWithRequest:urlRequest];
    [request setQueuePriority:NSOperationQueuePriorityVeryHigh];
    
    return request;
}



#pragma mark -
#pragma mark Observers

- (void)addDependent:(id)observer withPriority:(NSOperationQueuePriority)priority {
    RGAssert(observer);
    if (!observer) {
        return;
    }
    
    // TODO
//    [observer setAssociatedObject:@(priority) forKey:kPriorityKey];
    
    @synchronized(self) {
        [_dependents addObject:observer];
    }
}

- (void)removeDependent:(id)observer {
    RGAssert(observer);
    if (!observer) {
        return;
    }
    
    NSInteger numRemainingDependents = 0;
    NSOperationQueuePriority adjustedPriority = NSOperationQueuePriorityVeryLow;
    
    @synchronized(self) {
        [_dependents removeObject:observer];

        for (id dependent in _dependents) {
            NSOperationQueuePriority priority = dependent ? 0 : 0; // TODO
//            [[dependent getAssociatedObjectForKey:kPriorityKey] integerValue];
            adjustedPriority = MAX(adjustedPriority, priority);
            numRemainingDependents++;
        }
    }
    
    if (numRemainingDependents > 0) {
        [self setQueuePriority:adjustedPriority];
    } else {
        [self cancel];
    }
}

@end


#pragma mark -
#pragma mark POST

@implementation RGPostRequest

+ (RGRequest *)requestWithURL:(NSURL *)url parameters:(NSDictionary *)parameters files:(NSDictionary *)files {
    return [self updateRequestWithMethod:@"POST" url:url parameters:parameters files:files];
}

+ (RGRequest *)updateRequestWithMethod:(NSString *)method
                                   url:(NSURL *)url
                            parameters:(NSDictionary *)parameters
                                 files:(NSDictionary *)files {
    
    AFHTTPRequestOperationManager *client = [RGService sharedService].client;

    NSError *error = nil;
    NSMutableURLRequest *urlRequest = [client.requestSerializer requestWithMethod:method URLString:url.absoluteString parameters:parameters error:&error];
//    NSMutableURLRequest *urlRequest =
//    [client.requestSerializer multipartFormRequestWithMethod:method
//                                                   URLString:url.absoluteString
//                                                  parameters:parameters
//                                   constructingBodyWithBlock:^(id<AFMultipartFormData> formData)
//    {
//        for (NSString *fileName in files) {
//            RGDataUpload *dataUpload = [files objectForKey:fileName];
//            if (dataUpload.data) {
//                [formData appendPartWithFileData:dataUpload.data
//                                            name:fileName
//                                        fileName:fileName
//                                        mimeType:dataUpload.mimeType];
//            } else {
//                [formData appendPartWithInputStream:dataUpload.inputStream
//                                               name:fileName
//                                           fileName:fileName
//                                             length:dataUpload.length
//                                           mimeType:dataUpload.mimeType];
//            }
//        }
//    } error:nil];

    return [self requestFromURLRequest:urlRequest
                       timeoutInterval:kDefaultUploadRequestTimeoutInterval]; // TEMP
}

@end


#pragma mark -
#pragma mark PATCH

@implementation RGPatchRequest

+ (RGRequest *)requestWithURL:(NSURL *)url parameters:(NSDictionary *)parameters files:(NSDictionary *)files {
    return [self updateRequestWithMethod:@"PATCH" url:url parameters:parameters files:files];
}

@end


#pragma mark -
#pragma mark DELETE

@implementation RGDeleteRequest

+ (RGRequest *)requestWithURL:(NSURL *)url parameters:(NSDictionary *)parameters {
    AFHTTPRequestOperationManager *client = [RGService sharedService].client;
    
    NSMutableURLRequest *urlRequest =
    [client.requestSerializer requestWithMethod:@"DELETE"
                                      URLString:url.absoluteString
                                     parameters:parameters
                                          error:nil];
    
    return [self requestFromURLRequest:urlRequest];
}

@end


#pragma mark -
#pragma mark GET

@implementation RGGetRequest

+ (RGRequest *)requestWithURL:(NSURL *)url parameterString:(NSString *)parameterString {
    AFHTTPRequestOperationManager *client = [RGService sharedService].client;
    
    url = [url URLByAppendingParameterString:parameterString];
    
    NSMutableURLRequest *urlRequest =
    [client.requestSerializer requestWithMethod:@"GET"
                                      URLString:url.absoluteString
                                     parameters:nil
                                          error:nil];

    return [self requestFromURLRequest:urlRequest];
}

+ (RGRequest *)requestWithURL:(NSURL *)url parameters:(NSDictionary *)parameters {
    AFHTTPRequestOperationManager *client = [RGService sharedService].client;

    NSMutableURLRequest *urlRequest =
    [client.requestSerializer requestWithMethod:@"GET"
                                      URLString:url.absoluteString
                                     parameters:parameters
                                          error:nil];
    
    return [self requestFromURLRequest:urlRequest];
}

@end


#pragma mark -
#pragma mark Image request

@implementation RGRequest (ImageRequest)

- (void)notifySuccessWithData:(NSData *)data forURL:(NSURL *)url {
    NSArray *dependents = nil;
    @synchronized(self) {
        dependents = [[_dependents objectEnumerator] allObjects];
    }
    
    for (id dependent in dependents) {
        if ([dependent respondsToSelector:@selector(imageRequest:didLoadImageData:forURL:)]) {
            [dependent imageRequest:self didLoadImageData:data forURL:url];
        }
    }
}

- (void)notifyFailureWithError:(NSError *)error forURL:(NSURL *)url {
    NSArray *dependents = nil;
    @synchronized(self) {
        dependents = [[_dependents objectEnumerator] allObjects];
    }
    
    for (id dependent in dependents) {
        if ([dependent respondsToSelector:@selector(imageRequest:didFailWithError:forURL:)]) {
            [dependent imageRequest:self didFailWithError:error forURL:url];
        }
    }
}

@end
