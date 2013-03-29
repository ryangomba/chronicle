#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, JRPropertyType) {
    JRPropertyTypeUnsupported,
    JRPropertyTypeObject,
    JRPropertyTypeFloat,
    JRPropertyTypeDouble,
    JRPropertyTypeLongLong,
    JRPropertyTypeUnsignedLongLong,
    JRPropertyTypeBool,
    JRPropertyTypeInt,
};

@class PropertyInfo;

@interface JRRuntimeUtility : NSObject

// currently only supports object types, if you call it on a class
// that has dynamic non-object types it will assert
+ (PropertyInfo *)dynamicPropertyInfoForClass:(Class)class;

@end

@interface PropertyInfo : NSObject

@property (nonatomic, strong) NSSet *names;
@property (nonatomic, strong) NSSet *setters;
@property (nonatomic, strong) NSSet *getters;
@property (nonatomic, strong) NSDictionary *getterToTypeMap;
@property (nonatomic, strong) NSDictionary *setterToTypeMap;
@property (nonatomic, strong) NSDictionary *getterToNameMap;
@property (nonatomic, strong) NSDictionary *setterToNameMap;

@end
