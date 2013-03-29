//  Copyright 2013-present Ryan Gomba. All rights reserved.

#ifdef DEBUG
#define DebugLog(args...) _DebugLog(__FILE__,__LINE__,__PRETTY_FUNCTION__,args);
#else
#define DebugLog(args...)
#endif

#define ProdLog NSLog

static inline void _DebugLog(const char *file, int lineNumber, const char *funcName, NSString *format,...) {
    va_list ap;

    va_start (ap, format);
    if (![format hasSuffix: @"\n"]) {
        format = [format stringByAppendingString: @"\n"];
    }
    NSString *body =  [[NSString alloc] initWithFormat: format arguments: ap];
    va_end (ap);
    const char *threadName = [[[NSThread currentThread] name] UTF8String];
    NSString *fileName=[[NSString stringWithUTF8String:file] lastPathComponent];
    if (threadName && strlen(threadName) > 0) {
        fprintf(stderr,"%s/%s (%s:%d) %s",threadName,funcName,[fileName UTF8String],lineNumber,[body UTF8String]);
    } else {
        fprintf(stderr,"%p/%s (%s:%d) %s",[NSThread currentThread],funcName,[fileName UTF8String],lineNumber,[body UTF8String]);
    }
}

