#import "CHModel.h"

#import <objc/runtime.h>
#import "JRRuntimeUtility.h"

//static NSString * const kPKKey = @"pk";
//static NSString * const kDeletedKey = @"deleted";

@interface CHModel ()

@property (nonatomic, strong) NSMutableDictionary *cacheStorage;

@end

@implementation CHModel

@dynamic pk;
@dynamic deleted;

#pragma mark -
#pragma mark Constructors

+ (instancetype)newModel {
    return [self newModelWithPK:[NSUUID UUID].UUIDString];
}

+ (instancetype)newModelWithPK:(NSString *)pk {
    CHModel *model = [[self alloc] init];
    [model setObject:pk forKey:[self storageKeyForPropertyNamed:@"pk"]];
    return model;
}


#pragma mark -
#pragma mark Keys

+ (NSMutableDictionary *)propertyNameToStorageKeyMap {
    static NSMutableDictionary *maps;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        maps = [[NSMutableDictionary alloc] init];
    });
    NSMutableDictionary *propertyNameToStorageKeyMap = maps[NSStringFromClass(self)];
    if (!propertyNameToStorageKeyMap) {
        propertyNameToStorageKeyMap = [[NSMutableDictionary alloc] init];;
        maps[NSStringFromClass(self)] = propertyNameToStorageKeyMap;
    }
    return propertyNameToStorageKeyMap;
}

+ (void)setStorageKey:(NSString *)storageKey forPropertyName:(NSString *)propertyName {
    self.propertyNameToStorageKeyMap[propertyName] = storageKey;
}

+ (NSString *)storageKeyForPropertyNamed:(NSString *)propertyName {
    return self.propertyNameToStorageKeyMap[propertyName] ?: propertyName;
}


#pragma mark -
#pragma mark NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        for (NSString *storageKey in self.class.propertyNameToStorageKeyMap.allValues) {
             [self setObject:[aDecoder decodeObjectForKey:storageKey] forKey:storageKey];
        }
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    for (NSString *storageKey in self.class.propertyNameToStorageKeyMap.allValues) {
        [aCoder encodeObject:[self objectForKey:storageKey] forKey:storageKey];
    }
}


#pragma mark -
#pragma mark Dictionaries

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    if (self = [super init]) {
        [self updateWithDictionary:dictionary];
    }
    return self;
}

- (void)updateWithDictionary:(NSDictionary *)dictionary {
    for (NSString *storageKey in self.class.propertyNameToStorageKeyMap.allValues) {
        [self setObject:dictionary[storageKey] forKey:storageKey];
    }
}

- (NSDictionary *)dictionaryRepresentation {
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    for (NSString *storageKey in self.class.propertyNameToStorageKeyMap.allValues) {
        [dictionary setValue:[self objectForKey:storageKey] forKey:storageKey];
    }
    return dictionary;
}


#pragma mark -
#pragma mark Equality

- (BOOL)isEqual:(id)object {
    if (![object isKindOfClass:self.class]) {
        return NO;
    }
    return [[object pk] isEqualToString:self.pk];
}

- (NSUInteger)hash {
    return [self.pk hash];
}


#pragma mark -
#pragma mark Storage

- (NSMutableDictionary *)cacheStorage {
    if (!_cacheStorage) {
        _cacheStorage = [[NSMutableDictionary alloc] init];
    }
    return _cacheStorage;
}

- (id)objectForKey:(NSString *)key {
    @synchronized(self) {
        return [self.cacheStorage objectForKey:key];
    }
}

- (void)setObject:(id)object forKey:(NSString *)key {
    @synchronized(self) {
        id current = [self.cacheStorage valueForKeyPath:key];
        if (current == object || [[self.cacheStorage valueForKeyPath:key] isEqual:object]) {
            return;
        }
        
        [self.cacheStorage setValue:object forKey:key];
    }
}


#pragma mark -
#pragma mark Getter/Setter Cached Object Keys

- (NSString *)keyForGetter:(SEL)getter {
    NSDictionary *map = [JRRuntimeUtility dynamicPropertyInfoForClass:self.class].getterToNameMap;
    NSString *propertyName = [map objectForKey:NSStringFromSelector(getter)];
    return [self.class storageKeyForPropertyNamed:propertyName];
}

- (NSString *)keyForSetter:(SEL)setter {
    NSDictionary *map = [JRRuntimeUtility dynamicPropertyInfoForClass:self.class].setterToNameMap;
    NSString *propertyName = [map objectForKey:NSStringFromSelector(setter)];
    return [self.class storageKeyForPropertyNamed:propertyName];
}


#pragma mark -
#pragma mark Dynamic Setter/Getters

static id DynamicObjectGetter(CHModel *self, SEL _cmd) {
    return [self objectForKey:[self keyForGetter:_cmd]];
}

static void DynamicObjectSetter(CHModel *self, SEL _cmd, id value) {
    [self setObject:value forKey:[self keyForSetter:_cmd]];
}

static BOOL DynamicBoolGetter(CHModel *self, SEL _cmd) {
    return [[self objectForKey:[self keyForGetter:_cmd]] boolValue];
}

static void DynamicBoolSetter(CHModel *self, SEL _cmd, BOOL value) {
    [self setObject:@(value) forKey:[self keyForSetter:_cmd]];
}

static int32_t DynamicIntGetter(CHModel *self, SEL _cmd) {
    return [[self objectForKey:[self keyForGetter:_cmd]] intValue];
}

static void DynamicIntSetter(CHModel *self, SEL _cmd, int32_t value) {
    [self setObject:@(value) forKey:[self keyForSetter:_cmd]];
}

static float DynamicFloatGetter(CHModel *self, SEL _cmd) {
    return [[self objectForKey:[self keyForGetter:_cmd]] floatValue];
}

static void DynamicFloatSetter(CHModel *self, SEL _cmd, float value) {
    [self setObject:@(value) forKey:[self keyForSetter:_cmd]];
}

static double DynamicDoubleGetter(CHModel *self, SEL _cmd) {
    return [[self objectForKey:[self keyForGetter:_cmd]] doubleValue];
}

static void DynamicDoubleSetter(CHModel *self, SEL _cmd, double value) {
    [self setObject:@(value) forKey:[self keyForSetter:_cmd]];
}

static int64_t DynamicLongLongGetter(CHModel *self, SEL _cmd) {
    return [[self objectForKey:[self keyForGetter:_cmd]] longLongValue];
}

static void DynamicLongLongSetter(CHModel *self, SEL _cmd, int64_t value) {
    [self setObject:@(value) forKey:[self keyForSetter:_cmd]];
}

static unsigned long long DynamicUnsignedLongLongGetter(CHModel *self, SEL _cmd) {
    return [[self objectForKey:[self keyForGetter:_cmd]] unsignedLongLongValue];
}

static void DynamicUnsignedLongLongSetter(CHModel *self, SEL _cmd, unsigned long long value) {
    [self setObject:@(value) forKey:[self keyForSetter:_cmd]];
}


#pragma mark -
#pragma mark Instance Method Resolution

+ (void)initialize {
    [super initialize];
    
    PropertyInfo *info = [JRRuntimeUtility dynamicPropertyInfoForClass:self.class];
    for (NSString *name in info.names) {
        [self setStorageKey:name forPropertyName:name];
    }
}

+ (BOOL)resolveInstanceMethod:(SEL)aSEL {
    NSString *selector = NSStringFromSelector(aSEL);
    
    PropertyInfo *info = [JRRuntimeUtility dynamicPropertyInfoForClass:self.class];
    
    if ([info.getters containsObject:selector]) {
        JRPropertyType propertyType = [info.getterToTypeMap[selector] integerValue];
        switch (propertyType) {
            case JRPropertyTypeObject:
                class_addMethod(self, aSEL, (IMP)DynamicObjectGetter, "@@:");
                return YES;
            case JRPropertyTypeBool:
                class_addMethod(self, aSEL, (IMP)DynamicBoolGetter, "c@:");
                return YES;
            case JRPropertyTypeFloat:
                class_addMethod(self, aSEL, (IMP)DynamicFloatGetter, "f@:");
                return YES;
            case JRPropertyTypeDouble:
                class_addMethod(self, aSEL, (IMP)DynamicDoubleGetter, "d@:");
                return YES;
            case JRPropertyTypeInt:
                class_addMethod(self, aSEL, (IMP)DynamicIntGetter, "i@:");
                return YES;
            case JRPropertyTypeLongLong:
                class_addMethod(self, aSEL, (IMP)DynamicLongLongGetter, "q@:");
                return YES;
            case JRPropertyTypeUnsignedLongLong:
                class_addMethod(self, aSEL, (IMP)DynamicUnsignedLongLongGetter, "Q@:");
                return YES;
            case JRPropertyTypeUnsupported:
                return NO;
        }
        return NO;
    }
    
    if ([info.setters containsObject:selector]) {
        JRPropertyType propertyType = [info.setterToTypeMap[selector] integerValue];
        switch (propertyType) {
            case JRPropertyTypeObject:
                class_addMethod(self, aSEL, (IMP)DynamicObjectSetter, "v@:@");
                return YES;
            case JRPropertyTypeBool:
                class_addMethod(self, aSEL, (IMP)DynamicBoolSetter, "v@:c");
                return YES;
            case JRPropertyTypeFloat:
                class_addMethod(self, aSEL, (IMP)DynamicFloatSetter, "v@:f");
                return YES;
            case JRPropertyTypeDouble:
                class_addMethod(self, aSEL, (IMP)DynamicDoubleSetter, "v@:d");
                return YES;
            case JRPropertyTypeInt:
                class_addMethod(self, aSEL, (IMP)DynamicIntSetter, "v@:i");
                return YES;
            case JRPropertyTypeLongLong:
                class_addMethod(self, aSEL, (IMP)DynamicLongLongSetter, "v@:q");
                return YES;
            case JRPropertyTypeUnsignedLongLong:
                class_addMethod(self, aSEL, (IMP)DynamicUnsignedLongLongSetter, "v@:Q");
                return YES;
            case JRPropertyTypeUnsupported:
                return NO;
        }
        return NO;
    }
    
    return [super resolveInstanceMethod:aSEL];
}

@end
