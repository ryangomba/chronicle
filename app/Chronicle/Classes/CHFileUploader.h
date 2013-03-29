#import <AFNetworking/AFHTTPRequestOperationManager.h>

@interface CHFileUploader : AFHTTPRequestOperationManager

+ (id)uploadData:(NSData *)data
             key:(NSString *)key
        MIMEType:(NSString *)MIMEType
      completion:(void (^)(BOOL success, NSError *error))completion;

+ (void)cancelUpload:(id)token;

@end
