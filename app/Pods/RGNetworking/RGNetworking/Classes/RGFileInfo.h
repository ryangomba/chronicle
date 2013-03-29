// Copyright 2004-present Facebook. All Rights Reserved.

#include <utime.h>
#include <sys/stat.h>
#include <vector>
#include <string>

struct RGFileInfo {
    NSURL *url;
    time_t accessTime;
    off_t fileSize;
};

inline RGFileInfo RGFileInfoAtURL(NSURL *url) {
    RGFileInfo fileInfo = {
        .url = url,
        .accessTime = 0,
        .fileSize = std::numeric_limits<off_t>::max()
    };

    struct stat attrib;
    int error = stat(url.path.UTF8String, &attrib);
    if (!error) {
        fileInfo.accessTime = attrib.st_atime;
        fileInfo.fileSize = attrib.st_size;
    }

    return fileInfo;
}
