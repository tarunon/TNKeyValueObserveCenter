#TNKeyValueObserveCenter

##使い方
Key-Value ObservingをNSNotificationライクに使用するためのクラス。  
TNKeyValueObserveCenter <-> NSNotificationCenter  
TNKeyValueObserve <-> NSNotification  
純正KVOと異なり、removeObserverをdealloc時に記述する必要はない。  

##サンプル
```objc

// In your ViewController
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[TNKeyValueObserveCenter defaultCenter] addObserverForObject:self.view keyPath:@"frame" options:NSKeyValueObservingOptionNew handler:^(TNKeyValueObserve *observe) {
        NSLog(@"====== %@ frame changed(block): %@", observe.observee, observe.change);
    }];
    [[TNKeyValueObserveCenter defaultCenter] addObserver:self action:@selector(viewFrameChanged:) forObject:self.view keyPath:@"frame" options:NSKeyValueObservingOptionNew];
}

- (void)viewFrameChanged:(TNKeyValueObserve *)observe
{
    NSLog(@"====== %@ frame changed(selector): %@", observe.observee, observe.change);
}
