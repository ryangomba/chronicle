//  Copyright 2013-present Ryan Gomba. All rights reserved.

#define kRGMimeTypeJPEG @"image/jpeg"
#define kRGMimeTypePNG @"image/png"

@interface RGDataUpload : NSObject

@property (nonatomic, strong, readonly) NSData *data;
@property (nonatomic, strong, readonly) NSInputStream *inputStream;
@property (nonatomic, assign, readonly) long long length;
@property (nonatomic, strong, readonly) NSString *mimeType;

+ (RGDataUpload *)dataUploadWithData:(NSData *)data
                            mimeType:(NSString *)mimeType;

+ (RGDataUpload *)dataUploadWithInputStream:(NSInputStream *)inputStream
                                   mimeType:(NSString *)mimeType
                                     length:(long long)length;

@end
