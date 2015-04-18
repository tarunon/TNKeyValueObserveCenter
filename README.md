#TNKeyValueObserveCenter

Key-Value Observer like NSNotification.

TNKeyValueObserveCenter <-> NSNotificationCenter  
TNKeyValueObserve <-> NSNotification  

##How To
- Add observer using TNKeyValueObserveCenter.
- Get object and change from TNKeyValueObserve. It's observed methods first argument.

##Pod
pod 'TNKeyValueObserveCenter', :git => 'https://github.com/tarunon/TNKeyValueObserveCenter.git'

##Sample
```objc

// In your ViewController
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[TNKeyValueObserveCenter defaultCenter] addObserverForObject:self.view
                                                          keyPath:@"frame"
                                                          options:NSKeyValueObservingOptionNew
                                                          handler:^(TNKeyValueObserve *observe) {
        NSLog(@"====== %@ frame changed(block): %@", observe.object, observe.change);
    }];
    [[TNKeyValueObserveCenter defaultCenter] addObserver:self
                                                  action:@selector(viewFrameChanged:)
                                               forObject:self.view
                                                 keyPath:@"frame"
                                                 options:NSKeyValueObservingOptionNew];
}

- (void)viewFrameChanged:(TNKeyValueObserve *)observe
{
    NSLog(@"====== %@ frame changed(selector): %@", observe.object, observe.change);
}
