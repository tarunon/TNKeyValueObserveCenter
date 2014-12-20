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
- (void)performActionWithObservee:(id)observee change:(NSDictionary *)change;

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

@interface TNKeyValueObserveActionContainer : NSObject {
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

- (void)performActionWithObservee:(id)observee change:(NSDictionary *)change
{
    _handler([[TNKeyValueObserve alloc] initWithObservee:observee change:change]);
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

- (void)performActionWithObservee:(id)observee change:(NSDictionary *)change
{
    [_observer performSelector:_action withObject:[[TNKeyValueObserve alloc] initWithObservee:observee change:change]];
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

@end

@implementation TNKeyValueObserve

- (instancetype)initWithObservee:(id)observee change:(NSDictionary *)change
{
    if (self = [super init]) {
        _observee = observee;
        _change = change;
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init]) {
        _observee = [aDecoder decodeObjectForKey:@"observee"];
        _change = [aDecoder decodeObjectForKey:@"change"];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    return [[TNKeyValueObserve allocWithZone:zone] initWithObservee:_observee change:_change.copy];
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_observee forKey:@"observee"];
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

- (NSMapTable *)actionsForObject:(id)anObject keyPath:(NSString *)keyPath
{
    TNKeyValueObserveActionContainer *container = [anObject actionContainer_TNKeyValueObserve];
    if (!container) {
        [anObject setActionContainer_TNKeyValueObserve:(container = [[TNKeyValueObserveActionContainer alloc] init])];
    }
    NSMapTable *actions = container[keyPath];
    if (!actions) {
        actions = container[keyPath] = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsWeakMemory valueOptions:NSPointerFunctionsStrongMemory];
    }
    return actions;
}

- (void)addObserver:(id)observer action:(SEL)action forObject:(id)anObject keyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options
{
    [anObject addObserver:self forKeyPath:keyPath options:options context:nil];
    [[self actionsForObject:anObject keyPath:keyPath] setObject:[[TNKeyValueObserveAction alloc] initWithObserver:observer action:action] forKey:observer];
}

- (void)addObserverForObject:(id)anObject keyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options handler:(TNKeyValueObserveBlock)handler
{
    [anObject addObserver:self forKeyPath:keyPath options:options context:nil];
    [[self actionsForObject:anObject keyPath:keyPath] setObject:[[TNKeyValueObserveHandler alloc] initWithHandler:handler] forKey:anObject];
}

- (void)removeObserver:(id)observer forObject:(id)anObject keyPath:(NSString *)keyPath
{
    [[anObject actionContainer_TNKeyValueObserve][keyPath] removeObjectForKey:observer];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    NSMapTable *actions = [self actionsForObject:object keyPath:keyPath];
    for (id observer in actions) {
        id <TNKeyValueObserveActionProtocol> action = [actions objectForKey:observer];
        [action performActionWithObservee:object change:change];
    }
}

@end
