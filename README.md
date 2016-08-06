# gcd_example

一、首先来了解一下gcd术语:

(1). Serial VS Concurrent (串行 VS 并发)
```
任务串行执行就是每次只有一个任务被执行，
任务并发执行就是在同一时间可以有多个任务被执行
```

(2). Sync VS Async (同步 VS 异步)
```
一个同步函数只在完成了它预定的任务后才会返回，
一个异步函数刚好相反，会立即返回，预定的任务会完成，但不会等他完成，因此一个异步函数不会阻塞当前线程去执行下一个函数
```

(3). Critical Section (临界区)
```
简而言之就是两个或多个线程不能同时执行一段代码去操作一个共享的资源
```

(4). Race Condition (竞态条件)
```
这种情况是指基于特定序列或时机的事件的软件系统以不受控制的方式运行的行为，
竞态条件可导致无法预测的行为，例如程序的并发任务执行的确切顺序
```

(5). Deadlock (死锁)
```
所谓的死锁是指两个(或多个)线程都卡住了，都在等待对方完成后执行，
第一个不能完成是因为在等待第二个的完成，但第二个也不能完成，
是因为它在等待第一个完成
```

(6). Thread Safe (线程安全)
```
线程安全的代码能够在多线程及并发任务中被安全的调用，而不会导致任何问题(数据损坏、crash等)。
线程不安全的代码在某一时刻只能在一个上下文中运行。
一个线程安全代码的例子是NSDictionary，你可以在同一时间在多个线程中使用它而不会有问题。
而NSMutableDictionary就不是线程安全的，应该保证一次只能有一个线程访问它。
```

(7). Context Switch (上下文切换)
```
一个上下文切换指当你在单个进程里切换至行不通的线程时存储与恢复执行状态的过程。
这个过程在编写多任务应用时很普遍，通常会带来一些额外的开销
```

(8). Concurrency VS Parallelism (并发与并行)
```
并发：
    并发是指在执行多个线程时，需要进行上下文切换，然后运行另一个线程，
    例如有一个线程A和一个线程B，它们并发执行的方式就是，
    执行一会儿(这个时间非常非常短，短到我们感觉不到)线程A，
    进行上下文切换到线程B，再执行B线程，这样交替执行
并行：
    并行可以同时执行线程A和线程B，不需要进行上下文切换
```

(9). Queue (队列)
```
GCD提供有dispatch_queue来处理代码块，这些队列管理你提供给GCD的任务并用先进先出的顺序来执行这些任务，
这就保证了第一个被添加到队列里的任务会是队列中第一个开始的任务，
而第二个被添加的任务将第二个开始，如此直到队列的终点。
所有的调度队列(dispatch_queue)都是线程安全的，你能在多个线程并行的访问他们
```

(10). Serial Queue (串行队列)
```
串行队列能确保gcd一词只执行一个任务，并且按照我们添加到队列的顺序来执行，
由于在串行队列中不会有两个任务并发执行，因此不会出现同时访问临界区的风险
```

(11). Concurrent Queue (并发队列)
```
并发队列中的任务只能确保它们是按照被添加的顺序开始执行，我们并不能知道何时开始运行下一个任务，或者在某一时刻有多少任务在执行
```

(12). Queue Types (队列类型)
```
首先系统提供一个主队列(main_queue)的特殊队列，和其他串行队列一样，这个队列中的任务一次只能执行一个，主线程是唯一可用于更新UI的线程
另外，系统还提供了几个并发队列，它们叫做全局调度队列(global dispatch queue), 这几个全局队列有着不同的优先级：
background, low, default, high
除此之外，你还可以自己创建串行或者并发队列 (dispatch_queue_create)
```

二、接下来我们进入主题，看一下gcd的基本使用方法：

dispatch_async，常用方式如下：
```
dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
    // 在这里执行非UI操作
    dispatch_async(dispatch_get_main_queue(), ^{
        // 在这里更新UI
    });
});
```

dispatch_after，常用方式如下：
```
dispatch_time_t delayTime = dispatch_time(DISPATCH_TIME_NOW, (int_64)(1.0 * NSEC_PER_SEC));
// 注意：dispatch_after最好在主线程执行
dispatch_after(delayTime, dispatch_get_main_queue(), ^(void) {
    // 在这里执行要延后的操作
});
```

dispatch_once，常用方式如下：
```
// 使用dispatch_once构建单例，可以保证单例线程安全
+ (instancetype)shareInstance {
    static PhotoHandler *handler = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        handler = [[PhotoHandler alloc] init];
    });
    return handler;
}
```

dispatch_barrier，常用方式如下：
```
// 注意：自定义并发队列是使用dispatch_barrier的最佳选择
- (void)addPhoto:(Photo *)photo {
    if (!photo) { return; }
    // 使用dispatch_barrier确保在self.concurrentPhotoQueue这个并发队列中在执行这段代码时，这是在self.concurrentPhotoQueue中唯一执行的条目
    dispatch_barrier_async(self.concurrentPhotoQueue, ^{
        [_photoArray addObject:photo];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self postPhotoAddedNotification];
        });
    });
}
```

dispatch_sync，常用方法如下：
```
// 首先，既然需要从函数返回数据，所以就不能使用异步调度到队列，因为在你返回array之前可能其任务还没有执行
// 并发队列是使用dispatch_sync的最佳选择
- (NSArray *)photos {
    __block NSArray *array;
    dispatch_sync(self.concurrentPhotoQueue, ^{
        array = [NSArray arrayWithArray:_photoArray];
    });
    return array;
}
```

dispatch_group 及 dispatch_apply 常用方法如下：
```
- (void)downloadPhotosWithBlock:(BatchPhotoDownloadBlock)block {
    __block NSError *_error;
    // 创建一个新的dispatch_group
    dispatch_group_t download_group = dispatch_group_create();
    // 循环3次
    // 注意：太多的并发数量会带来一定的风险，dispatch_apply表现的像一个for循环，但它能并发地执行不同的迭代
    // 使用dispatch_apply可以有效的减少并发数量，并发队列对于dispatch_apply来说是最好的选择
    dispatch_apply(3, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^(size_t i) {
        NSURL *URL;
        switch (i) {
            case 0:
                URL = [NSURL URLWithString:kFirstImageURL];
            break;
            case 1:
                URL = [NSURL URLWithString:kSecondImageURL];
            break;
            case 2:
                URL = [NSURL URLWithString:kThirdImageURL];
            break;
        }
        // 通知dispatch_group已经开始，必须保证dispatch_group_enter和dispatch_group_leave成对出现，否则可能会导致崩溃  
        dispatch_group_enter(download_group);
        Photo *photo = [[Photo alloc] initWithURL:URL withCompletionBlock:^(UIImage *image, NSError *error) {
            if (error) {
                _error = error;
            }
            // 通知group他的工作已经完成
            dispatch_group_leave(download_group);
        }];
        [[PhotoHandler shareInstance] addPhoto:photo];
    });
    // group的所有任务都已经完成，收到通知
    // 注意：dispatch_group_notify是异步操作，还有一种是dispatch_group_wait，是同步工作，一般较少使用
    dispatch_group_notify(download_group, dispatch_get_main_queue(), ^{
        // 收到通知后执行的任务
        Block_exe(block, _error);
    });
}
```

dispatch_semaphore，常用方式如下：
```
// 创建一个信号量，参数指定信号量的初始值，这个数字是你可以访问的信号量，这里初始化为0也就是说，有人想使用信号量必然会被阻塞，知道有人增加信号量
dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
NSURL *URL = [NSURL URLWithString:kFirstImageURL];
__unused Photo *photo = [[Photo alloc] initWithURL:URL withCompletionBlock:^(UIImage *image, NSError *error) {
    if (error) {
        NSLog(@"error : %@", error.localizedDescription);
    }
    // 当获取image完成后，通知信号量你不再不要资源量，这时信号量的计数会增加并告知其他想使用此资源的线程
    dispatch_semaphore_signal(semaphore);
    NSLog(@"image : %@", image);
}];
dispatch_time_t timeout_time = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC));
// dispatch_semaphore_wait 返回值为0成功，非0超时
// 在超时之前等待信号量，这个调用阻塞了当前线程直到信号量被发射
// 这个函数的一个非0返回值表示超时了
long semaphore_value = dispatch_semaphore_wait(semaphore, timeout_time);
if (semaphore_value) {
    // 这里是超时执行的动作
    NSLog(@"time out ... URL: %@", URL.absoluteString);
}
```

dispatch_source，常用方法如下：
```
__block NSInteger timeOutCount = 10;
// 时间间隔
uint64_t interval_seconds = 1;
dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
dispatch_source_set_timer(timer, DISPATCH_TIME_NOW, interval_seconds * NSEC_PER_SEC, 0 * NSEC_PER_SEC);
// 设置回调
dispatch_source_set_event_handler(timer, ^{
    NSLog(@"time count : %zd", timeOutCount);
    if (timeOutCount == 0) {
    // 取消timer
        dispatch_source_cancel(timer);
    }
    timeOutCount --;
});
// 启动timer
dispatch_resume(timer);
```

最后给大家推荐一篇gcd详解的文章:[https://github.com/ming1016/study/wiki/%E7%BB%86%E8%AF%B4GCD%EF%BC%88Grand-Central-Dispatch%EF%BC%89%E5%A6%82%E4%BD%95%E7%94%A8](https://github.com/ming1016/study/wiki/%E7%BB%86%E8%AF%B4GCD%EF%BC%88Grand-Central-Dispatch%EF%BC%89%E5%A6%82%E4%BD%95%E7%94%A8)
