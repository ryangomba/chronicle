//  Copyright 2013-present Ryan Gomba. All rights reserved.

#import "RGDataUpload.h"

@interface RGDataUpload ()

@property (nonatomic, strong, readwrite) NSData *data;
@property (nonatomic, strong, readwrite) NSInputStream *inputStream;
@property (nonatomic, assign, readwrite) long long length;
@property (nonatomic, strong, readwrite) NSString *mimeType;

@end


@implementation RGDataUpload

+ (RGDataUpload *)dataUploadWithData:(NSData *)data
                            mimeType:(NSString *)mimeType {
    
    RGDataUpload *dataUpload = [[RGDataUpload alloc] init];
    [dataUpload setData:data];
    [dataUpload setLength:data.length];
    [dataUpload setMimeType: mimeType];
    return dataUpload;
}

+ (RGDataUpload *)dataUploadWithInputStream:(NSInputStream *)inputStream
                                   mimeType:(NSString *)mimeType
                                     length:(long long)length {

    RGDataUpload *dataUpload = [[RGDataUpload alloc] init];
    [dataUpload setInputStream:inputStream];
    [dataUpload setMimeType: mimeType];
    [dataUpload setLength:length];
    return dataUpload;
}

@end
