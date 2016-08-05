//
//  Photo.m
//  GCD_Example
//
//  Created by 雷亮 on 16/8/5.
//  Copyright © 2016年 Leiliang. All rights reserved.
//

#import "Photo.h"
#import "UIImage+Resize.h"
#import "Utils.h"

#pragma mark -
#pragma mark - Private Class AssetPhoto
@interface AssetPhoto : Photo

@property (nonatomic, strong) ALAsset *asset;

@end

@implementation AssetPhoto

- (UIImage *)thumbnail {
    return [UIImage imageWithCGImage:[self.asset thumbnail]];
}
            
- (UIImage *)image {
    ALAssetRepresentation *representation = [self.asset defaultRepresentation];
    return [UIImage imageWithCGImage:[representation fullScreenImage]];
}

- (PhotoStatus)status {
    return PhotoStatusSuccess;
}

@end

#pragma mark -
#pragma mark - Private Class DownloadPhoto
@interface DownloadPhoto : Photo

@property (nonatomic, strong, readwrite) UIImage *image;
@property (nonatomic, strong, readwrite) NSURL *URL;
@property (nonatomic, strong, readwrite) UIImage *thumbnail;

@end

@implementation DownloadPhoto

@synthesize status = _status;

- (void)downloadImageWithCompletion:(PhotoDownloadBlock)block {
    static NSURLSession *session;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
        session = [NSURLSession sessionWithConfiguration:configuration];
    });
    NSURLSessionDataTask *task = [session dataTaskWithURL:self.URL completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        self.image = [UIImage imageWithData:data];
        if (!error && _image) {
            _status = PhotoStatusSuccess;
        } else {
            _status = PhotoStatusFailed;
        }
        self.thumbnail = [_image thumbnailImage:64 transparentBorder:0 cornerRadius:0 interpolationQuality:kCGInterpolationDefault];
        Block_exe(block, self.image, error);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSNotification *notification = [NSNotification notificationWithName:kPhotoManagerUpdateContentNotification object:nil];
            [[NSNotificationQueue defaultQueue] enqueueNotification:notification postingStyle:NSPostASAP coalesceMask:NSNotificationCoalescingOnName forModes:nil];
        });
    }];
    [task resume];
}

- (UIImage *)thumbnail {
    return _thumbnail;
}

- (UIImage *)image {
    return _image;
}

- (PhotoStatus)status {
    return _status;
}

@end

@interface Photo ()

@property (nonatomic, assign, readwrite) PhotoStatus status;

@end

@implementation Photo

- (instancetype)initWithAsset:(ALAsset *)asset {
    AssetPhoto *assetPhoto = [[AssetPhoto alloc] init];
    if (assetPhoto) {
        assetPhoto.asset = asset;
        assetPhoto.status = PhotoStatusSuccess;
    }
    return assetPhoto;
}

- (instancetype)initWithURL:(NSURL *)URL {
    DownloadPhoto *downloadPhoto = [[DownloadPhoto alloc] init];
    if (downloadPhoto) {
        downloadPhoto.status = PhotoStatusDownloading;
        downloadPhoto.URL = URL;
        [downloadPhoto downloadImageWithCompletion:nil];
    }
    return downloadPhoto;
}

- (instancetype)initWithURL:(NSURL *)URL withCompletionBlock:(PhotoDownloadBlock)block {
    DownloadPhoto *downloadPhoto = [[DownloadPhoto alloc] init];
    if (downloadPhoto) {
        downloadPhoto.status = PhotoStatusDownloading;
        downloadPhoto.URL = URL;
        [downloadPhoto downloadImageWithCompletion:[block copy]];
    }
    return downloadPhoto;
}

- (PhotoStatus)status {
    return PhotoStatusFailed;
}

- (UIImage *)image {
    return nil;
}

- (UIImage *)thumbnail {
    return nil;
}

@end
