//
//  PhotoHandler.m
//  GCD_Example
//
//  Created by 雷亮 on 16/8/5.
//  Copyright © 2016年 Leiliang. All rights reserved.
//

#import "PhotoHandler.h"
#import "Utils.h"

@interface PhotoHandler ()

@property (nonatomic, strong) NSMutableArray <Photo *>*photoArray;
@property (nonatomic, strong) dispatch_queue_t concurrentQueue;

@end

@implementation PhotoHandler

+ (instancetype)shareInstance {
    static PhotoHandler *handler = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        handler = [[PhotoHandler alloc] init];
        handler.photoArray = [NSMutableArray array];
        handler.concurrentQueue = dispatch_queue_create("com.github.slipawayleaon", DISPATCH_QUEUE_CONCURRENT);
    });
    return handler;
}

- (NSArray *)photos {
    __block NSArray *photos;
    dispatch_sync(self.concurrentQueue, ^{
        photos = [NSArray arrayWithArray:_photoArray];
    });
    return photos;
}

- (void)addPhoto:(Photo *)photo {
    if (!photo) { return; }
    dispatch_barrier_async(self.concurrentQueue, ^{
        [_photoArray addObject:photo];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self postPhotoAddedNotification];
        });
    });
}

- (void)removePhoto:(Photo *)photo {
    if (!photo) { return; }
    dispatch_barrier_async(self.concurrentQueue, ^{
        [_photoArray removeObject:photo];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self postPhotoAddedNotification];
        });
    });
}

- (void)removeAllPhotos {
    dispatch_barrier_async(self.concurrentQueue, ^{
        [_photoArray removeAllObjects];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self postPhotoAddedNotification];
        });
    });
}

- (void)downloadPhotosWithBlock:(BatchPhotoDownloadBlock)block {
    __block NSError *_error;
    dispatch_group_t download_group = dispatch_group_create();
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
        dispatch_group_enter(download_group);
        Photo *photo = [[Photo alloc] initWithURL:URL withCompletionBlock:^(UIImage *image, NSError *error) {
            if (error) {
                _error = error;
            }
            dispatch_group_leave(download_group);
        }];
        [[PhotoHandler shareInstance] addPhoto:photo];
    });
    
    dispatch_group_notify(download_group, dispatch_get_main_queue(), ^{
        Block_exe(block, _error);
    });
}

#pragma mark -
#pragma mark - privite methods
- (void)postPhotoAddedNotification {
    static NSNotification *notification = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        notification = [NSNotification notificationWithName:kPhotoManagerAddedContentNotification object:nil];
    });
    [[NSNotificationQueue defaultQueue] enqueueNotification:notification postingStyle:NSPostASAP coalesceMask:NSNotificationCoalescingOnName forModes:nil];
}

@end
