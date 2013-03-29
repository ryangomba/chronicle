//  Copyright 2013-present Ryan Gomba. All rights reserved.

#define RGAssert(expression, ...) \
    do { \
        if(!(expression)) { \
            NSString *errorFormat = @"Assertion failure: %s in %s on line %s:%d. %@"; \
            NSString *errorString = [NSString stringWithFormat:errorFormat, \
            #expression,  __func__, __FILE__, __LINE__, [NSString stringWithFormat: @"" __VA_ARGS__]]; \
            NSLog(@"%@", errorString); \
            abort(); \
        } \
    } while(0)
