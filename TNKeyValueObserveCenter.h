//
//  TNKeyValueObserver.h
//  Libing
//
//  Created by tarunon on 2014/11/28.
//  Copyright (c) 2014年 tarunon. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TNKeyValueObserve : NSObject <NSCopying, NSCoding>

@property (readonly) id observee;
@property (readonly, copy) NSDictionary *change;

- (instancetype)initWithObservee:(id)observee change:(NSDictionary *)change;

@end

typedef void (^TNKeyValueObserveBlock)(TNKeyValueObserve *observe);

@interface TNKeyValueObserveCenter : NSObject

+ (instancetype)defaultCenter;

- (void)addObserver:(id)observer action:(SEL)action forObject:(id)anObject keyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options;
- (void)addObserverForObject:(id)anObject keyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options handler:(TNKeyValueObserveBlock)handler;

- (void)removeObserver:(id)observer forObject:(id)anObject keyPath:(NSString *)keyPath;

@end
