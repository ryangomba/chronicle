#import "CHFileUploader.h"

#import "AFAmazonS3RequestSerializer.h"

@interface CHFileUploader ()

@property (nonatomic, strong) AFAmazonS3RequestSerializer<AFURLRequestSerialization> *requestSerializer;
@property (nonatomic, strong) NSMapTable *ongoingRequests;

@end

@implementation CHFileUploader

@dynamic requestSerializer;

+ (instancetype)sharedFileUploader {
    static CHFileUploader *uploader;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        uploader = [[self alloc] init];
        
        uploader.ongoingRequests = [NSMapTable strongToWeakObjectsMapTable];
        
        uploader.requestSerializer = [AFAmazonS3RequestSerializer serializer];
        // TODO: set securely
        // [uploader.requestSerializer setAccessKeyID:@"" secret:@""];
        uploader.requestSerializer.region = AFAmazonS3USStandardRegion;
        uploader.requestSerializer.bucket = @"chronicle-scratch";
        uploader.requestSerializer.timeoutInterval = 60.0;
        
        uploader.responseSerializer = [AFXMLParserResponseSerializer serializer];
    });
    return uploader;
}

+ (id)uploadData:(NSData *)data
             key:(NSString *)key
        MIMEType:(NSString *)MIMEType
      completion:(void (^)(BOOL, NSError *))completion {
    
    return [[self sharedFileUploader] uploadData:data
                                             key:key
                                        MIMEType:MIMEType
                                      completion:completion];
}

+ (void)cancelUpload:(id)token {
    [[self sharedFileUploader] cancelUpload:token];
}

- (id)uploadData:(NSData *)data
             key:(NSString *)key
        MIMEType:(NSString *)MIMEType
      completion:(void (^)(BOOL, NSError *))completion {
    
    NSString *URLString = [[self.requestSerializer.endpointURL URLByAppendingPathComponent:key] absoluteString];
    NSURLRequest *request = [self.requestSerializer requestWithMethod:@"PUT"
                                                            URLString:URLString
                                                           parameters:@{@"key": key}
                                                                 data:data
                                                             mimeType:MIMEType];
    
    AFHTTPRequestOperation *requestOperation =
    [self HTTPRequestOperationWithRequest:request success:
     ^(AFHTTPRequestOperation *operation, id responseObject) {
         if (completion) {
             completion(YES, nil);
         }
     } failure:^(__unused AFHTTPRequestOperation *operation, NSError *error) {
         if (completion) {
             completion(NO, error);
         }
     }];
    
    [requestOperation setUploadProgressBlock:
     ^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
         CGFloat percentComplete = totalBytesWritten / (CGFloat)totalBytesExpectedToWrite;
         NSLog(@"Upload progress: %f", percentComplete);
    }];
    
    [self.operationQueue addOperation:requestOperation];
    
    NSString *token = [[NSUUID UUID] UUIDString];
    [self.ongoingRequests setObject:requestOperation forKey:token];
    return token;
}

- (void)cancelUpload:(id)token {
    NSLog(@"Canceling upload with token: %@", token);
    
    if (!token) {
        NSLog(@"nil token, nevermind");
        return;
    }
    
    AFHTTPRequestOperation *operation = [self.ongoingRequests objectForKey:token];
    if (!operation) {
        NSLog(@"operation finished, nevermind");
    }
    [operation cancel];
}

@end
