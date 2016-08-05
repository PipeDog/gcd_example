//
//  Photo.h
//  GCD_Example
//
//  Created by 雷亮 on 16/8/5.
//  Copyright © 2016年 Leiliang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <UIKit/UIKit.h>

typedef void (^PhotoDownloadBlock) (UIImage *image, NSError *error);

typedef NS_ENUM(NSInteger, PhotoStatus) {
    PhotoStatusDownloading = 0,
    PhotoStatusSuccess = 1,
    PhotoStatusFailed = 2,
};

@interface Photo : NSObject

- (instancetype)initWithAsset:(ALAsset *)asset;

- (instancetype)initWithURL:(NSURL *)URL;

- (instancetype)initWithURL:(NSURL *)URL withCompletionBlock:(PhotoDownloadBlock)block;

/// 图像状态
@property (nonatomic, assign, readonly) PhotoStatus status;

/// 原始图像
- (UIImage *)image;

/// 缩略图
- (UIImage *)thumbnail;

@end
