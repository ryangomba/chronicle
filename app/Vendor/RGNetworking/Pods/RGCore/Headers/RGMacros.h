//  Copyright 2013-present Ryan Gomba. All rights reserved.

#import <QuartzCore/QuartzCore.h>

#define MIN_MAX(A,B,C) ({ \
__typeof__(A) __a = (A); __typeof__(B) __b = (B); __typeof__(C) __c = (C); \
__a < __b ? __b : (__a > __c ? __c : __a); \
})

#define StartTimer() CFTimeInterval __startTimer = CACurrentMediaTime();
#define RestartTimer() __startTimer = CACurrentMediaTime();
#define PrintTimeElapsedMessage(message) DebugLog(@"Time elapsed: %.2f ms (%@)", (CACurrentMediaTime() - __startTimer) * 1000.0, message);
#define PrintTimeElapsed() PrintTimeElapsedMessage(@"");

#define THROW_UNIMPLEMENTED_EXCEPTION \
NSString *reason = [NSString stringWithFormat:@"You must override %@ in a subclass", \
NSStringFromSelector(_cmd)]; \
@throw [NSException exceptionWithName:NSInternalInconsistencyException reason:reason userInfo:nil];

#define weakify(arg) \
typeof(arg) __weak ig_weak_##arg = arg

#define strongify(arg) \
_Pragma("clang diagnostic push") \
_Pragma("clang diagnostic ignored \"-Wshadow\"") \
typeof(arg) arg = ig_weak_##arg \
_Pragma("clang diagnostic pop")

#define DNC [NSNotificationCenter defaultCenter]
#define SUD [NSUserDefaults standardUserDefaults]
