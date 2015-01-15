//
//  TNKeyValueObserver.m
//  Libing
//
//  Created by tarunon on 2014/11/28.
//  Copyright (c) 2014年 tarunon. All rights reserved.
//

#import "TNKeyValueObserveCenter.h"
#import <objc/runtime.h>

@protocol TNKeyValueObserveActionProtocol
@required
- (void)performActionWithObject:(id)object change:(NSDictionary *)change;

@end

@interface TNKeyValueObserveHandler : NSObject <TNKeyValueObserveActionProtocol>

@property (nonatomic, readonly, copy) TNKeyValueObserveBlock handler;

- (instancetype)initWithHandler:(TNKeyValueObserveBlock)handler;

@end

@interface TNKeyValueObserveAction : NSObject <TNKeyValueObserveActionProtocol>

@property (nonatomic, readonly, unsafe_unretained) id observer;
@property (nonatomic, readonly) SEL action;

- (instancetype)initWithObserver:(id)observer action:(SEL)action;

@end

@interface TNKeyValueObserveActionContainer : NSObject <NSFastEnumeration> {
    NSMutableDictionary *_container;
}

@property (nonatomic, unsafe_unretained) id anObject;

- (id)objectForKeyedSubscript:(id)key;
- (void)setObject:(id)obj forKeyedSubscript:(id <NSCopying>)key;

@end


@interface NSObject(TNKeyValueObserve)

@property (nonatomic) TNKeyValueObserveActionContainer *actionContainer_TNKeyValueObserve;

@end

@implementation TNKeyValueObserveHandler

- (instancetype)initWithHandler:(TNKeyValueObserveBlock)handler
{
    if (self = [super init]) {
        _handler = handler;
    }
    return self;
}

- (void)performActionWithObject:(id)object change:(NSDictionary *)change
{
    _handler([[TNKeyValueObserve alloc] initWithObject:object change:change]);
}

@end

@implementation TNKeyValueObserveAction

- (instancetype)initWithObserver:(id)observer action:(SEL)action
{
    if (self = [super init]) {
        _observer = observer;
        _action = action;
    }
    return self;
}

- (void)performActionWithObject:(id)object change:(NSDictionary *)change
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [_observer performSelector:_action withObject:[[TNKeyValueObserve alloc] initWithObject:object change:change]];
#pragma clang diagnostic pop
}

@end

@implementation NSObject(TNKeyValueObserve)

static void *actionContainer_TNKeyValueObserveKey = &actionContainer_TNKeyValueObserveKey;

- (TNKeyValueObserveActionContainer *)actionContainer_TNKeyValueObserve
{
    return objc_getAssociatedObject(self, actionContainer_TNKeyValueObserveKey);
}

- (void)setActionContainer_TNKeyValueObserve:(TNKeyValueObserveActionContainer *)actionContainer_TNKeyValueObserve
{
    actionContainer_TNKeyValueObserve.anObject = self;
    objc_setAssociatedObject(self, actionContainer_TNKeyValueObserveKey, actionContainer_TNKeyValueObserve, OBJC_ASSOCIATION_RETAIN);
}

@end

@implementation TNKeyValueObserveActionContainer

- (instancetype)init
{
    if (self = [super init]) {
        _container = @{}.mutableCopy;
    }
    return self;
}

- (void)dealloc
{
    for (NSString *keyPath in _container) {
        [_anObject removeObserver:[TNKeyValueObserveCenter defaultCenter] forKeyPath:keyPath];
    }
}

- (id)objectForKeyedSubscript:(id)key
{
    return _container[key];
}

- (void)setObject:(id)obj forKeyedSubscript:(id<NSCopying>)key
{
    _container[key] = obj;
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(__unsafe_unretained id [])buffer count:(NSUInteger)len
{
    NSUInteger bIdx = 0;
    NSUInteger lIdx = state->state;
    NSUInteger lLen = _container.count;
    while (bIdx < len) {
        if (lIdx >= lLen) {
            break;
        }
        buffer[bIdx++] = _container.allValues[lIdx++];
    }
    state->state = lIdx;
    state->itemsPtr = buffer;
    state->mutationsPtr = (unsigned long *)(__bridge void *)self;
    return bIdx;
}

@end

@implementation TNKeyValueObserve

- (instancetype)initWithObject:(id)object change:(NSDictionary *)change
{
    if (self = [super init]) {
        _object = object;
        _change = change;
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init]) {
        _object = [aDecoder decodeObjectForKey:@"object"];
        _change = [aDecoder decodeObjectForKey:@"change"];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    return [[TNKeyValueObserve allocWithZone:zone] initWithObject:_object change:_change.copy];
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_object forKey:@"object"];
    [aCoder encodeObject:_change forKey:@"change"];
}

@end

@implementation TNKeyValueObserveCenter

+ (instancetype)defaultCenter
{
    static TNKeyValueObserveCenter *_defaultCenter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _defaultCenter = [[self alloc] init];
    });
    return _defaultCenter;
}

- (NSMapTable *)actionsForObject:(id)object keyPath:(NSString *)keyPath
{
    TNKeyValueObserveActionContainer *container = [object actionContainer_TNKeyValueObserve];
    if (!container) {
        [object setActionContainer_TNKeyValueObserve:(container = [[TNKeyValueObserveActionContainer alloc] init])];
    }
    NSMapTable *actions = container[keyPath];
    if (!actions) {
        actions = container[keyPath] = [NSMapTable weakToStrongObjectsMapTable];
    }
    return actions;
}

- (void)addObserver:(id)observer action:(SEL)action forObject:(id)object keyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options
{
    [object addObserver:self forKeyPath:keyPath options:options context:nil];
    [[self actionsForObject:object keyPath:keyPath] setObject:[[TNKeyValueObserveAction alloc] initWithObserver:observer action:action] forKey:observer];
}

- (void)removeObserver:(id)observer forObject:(id)object keyPath:(NSString *)keyPath
{
    [[self actionsForObject:object keyPath:keyPath] removeObjectForKey:observer];
}

- (id <NSObject>)addObserverForObject:(id)object keyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options handler:(TNKeyValueObserveBlock)handler
{
    [object addObserver:self forKeyPath:keyPath options:options context:nil];
    TNKeyValueObserveHandler *observeHandler = [[TNKeyValueObserveHandler alloc] initWithHandler:handler];
    [[self actionsForObject:object keyPath:keyPath] setObject:observeHandler forKey:object];
    return observeHandler;
}

- (void)removeObserver:(id<NSObject>)observer forObject:(id)object
{
    for (NSMapTable *table in [object actionContainer_TNKeyValueObserve]) {
        if ([table objectForKey:object] == observer) {
            [table removeObjectForKey:object];
        }
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    NSMapTable *actions = [self actionsForObject:object keyPath:keyPath];
    for (id observer in actions) {
        id <TNKeyValueObserveActionProtocol> action = [actions objectForKey:observer];
        [action performActionWithObject:object change:change];
    }
}

@end
