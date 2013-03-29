#import "JRRuntimeUtility.h"

#import <objc/runtime.h>

@implementation JRRuntimeUtility

NS_INLINE const char *token_advance(const char *attributes) {
    while (0 != attributes[0] && ',' != attributes[0]) {
        attributes++;
    }
    return attributes;
}

+ (PropertyInfo *)dynamicPropertyInfoForClass:(Class)class {
    static NSMapTable *map;
    @synchronized(self) {
        if (!map) {
            map = [NSMapTable strongToStrongObjectsMapTable];
        }
        PropertyInfo *existing = [map objectForKey:class];
        if (existing) {
            return existing;
        }

        NSMutableSet *getters = [[NSMutableSet alloc] init];
        NSMutableSet *setters = [[NSMutableSet alloc] init];
        NSMutableSet *names = [[NSMutableSet alloc] init];
        NSMutableDictionary *getterToNameMap = [[NSMutableDictionary alloc] init];
        NSMutableDictionary *setterToNameMap = [[NSMutableDictionary alloc] init];
        NSMutableDictionary *getterToTypeMap = [[NSMutableDictionary alloc] init];
        NSMutableDictionary *setterToTypeMap = [[NSMutableDictionary alloc] init];

        Class currentClass = class;
        while(currentClass != [NSObject class]) {
            unsigned int outCount, i;
            objc_property_t *properties = class_copyPropertyList(currentClass, &outCount);
            for (i = 0; i < outCount; i++) {
                objc_property_t property = properties[i];
                const char *attributes = property_getAttributes(property);
                const char *name = property_getName(property);
                SEL getter = nil;
                SEL setter = nil;
                BOOL isDynamic = NO;
                BOOL isReadonly = NO;
                JRPropertyType propertyType;
                const char *attribute = attributes;
                const char *token;

                while (attribute && 0 != attribute[0]) {
                    char buf[256];
                    switch (attribute[0]) {
                        case 'T': {
                            // objc type
                            token = token_advance(attribute);
                            size_t len = token - attribute - 1;
                            memcpy(buf, attribute + 1, len); buf[len] = '\0';

                            if (buf[0] == '@') {
                                propertyType = JRPropertyTypeObject;
                            } else if (buf[0] == 'c') {
                                propertyType = JRPropertyTypeBool;
                            } else if (buf[0] == 'B') {
                                propertyType = JRPropertyTypeBool;
                            } else if (buf[0] == 'f') {
                                propertyType = JRPropertyTypeFloat;
                            } else if (buf[0] == 'd') {
                                propertyType = JRPropertyTypeDouble;
                            } else if (buf[0] == 'i') {
                                propertyType = JRPropertyTypeInt;
                            } else if (buf[0] == 'q') {
                                propertyType = JRPropertyTypeLongLong;
                            } else if (buf[0] == 'Q') {
                                propertyType = JRPropertyTypeUnsignedLongLong;
                            } else {
                                printf("Unsupported property type: %c", buf[0]);
                                propertyType = JRPropertyTypeUnsupported;
                                // 's': short
                                // 'l': long
                                // 'I': unsigned int
                                // 'S': unsigned short
                                // 'L': unsigned long
                                // 'B': BOOL
                            }

                            attribute = token;
                            break;
                        }
                        case ',': {
                            // token
                            attribute += 1;
                            break;
                        }
                        case 'G': {
                            // custom getter
                            token = token_advance(attribute);
                            size_t len = token - attribute - 1;
                            memcpy(buf, attribute + 1, len); buf[len] = '\0';
                            getter = sel_registerName(buf);
                            attribute = token;
                            break;
                        }
                        case 'S': {
                            // custom setter
                            token = token_advance(attribute);
                            size_t len = token - attribute - 1;
                            memcpy(buf, attribute + 1, len); buf[len] = '\0';
                            setter = sel_registerName(buf);
                            attribute = token;
                            break;
                        }
                        case 'D': {
                            // dynamic
                            token = token_advance(attribute);
                            size_t len = token - attribute - 1;
                            memcpy(buf, attribute + 1, len); buf[len] = '\0';
                            isDynamic = YES;
                            attribute = token;
                            break;
                        }
                        case 'R': {
                            // readonly
                            token = token_advance(attribute);
                            size_t len = token - attribute - 1;
                            memcpy(buf, attribute + 1, len); buf[len] = '\0';
                            isReadonly = YES;
                            attribute = token;
                            break;
                        }
                        default: {
                            attribute = token_advance(attribute);
                            break;
                        }
                    }
                }

                if (isDynamic) {

                    if (!getter) {
                        getter = sel_registerName(name);
                    }

                    if (propertyType == JRPropertyTypeUnsupported) {
                        NSAssert(NO, @"only a few types are supported for dynamic models properties at this time");
                    }

                    NSString *getterString = NSStringFromSelector(getter);
                    NSString *UTF8Name = [NSString stringWithUTF8String:name];
                    [getters addObject:getterString];
                    [names addObject:UTF8Name];
                    [getterToNameMap setObject:UTF8Name forKey:getterString];
                    [getterToTypeMap setObject:@(propertyType) forKey:getterString];

                    if (!setter && !isReadonly) {
                        char s[512] = "set";
                        strcat(s, name);
                        strcat(s, ":");
                        s[3] = toupper(s[3]);
                        setter = sel_registerName(s);

                        NSString *setterString = NSStringFromSelector(setter);
                        [setters addObject:setterString];
                        [setterToNameMap setObject:UTF8Name forKey:setterString];
                        [setterToTypeMap setObject:@(propertyType) forKey:setterString];
                    }
                }
            }
            free(properties);
            currentClass = class_getSuperclass(currentClass);
        }

        PropertyInfo *info = [[PropertyInfo alloc] init];
        info.setters = setters;
        info.getters = getters;
        info.names = names;
        info.getterToNameMap = getterToNameMap;
        info.setterToNameMap = setterToNameMap;
        info.getterToTypeMap = getterToTypeMap;
        info.setterToTypeMap = setterToTypeMap;
        [map setObject:info forKey:class];
        
        return info;
    }
}

@end


@implementation PropertyInfo

@end
