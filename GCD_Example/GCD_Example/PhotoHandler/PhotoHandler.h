//
//  PhotoHandler.h
//  GCD_Example
//
//  Created by 雷亮 on 16/8/5.
//  Copyright © 2016年 Leiliang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Photo.h"

typedef void (^BatchPhotoDownloadBlock) (NSError *error);

@interface PhotoHandler : NSObject

+ (instancetype)shareInstance;

- (NSArray *)photos;

- (void)addPhoto:(Photo *)photo;

- (void)removePhoto:(Photo *)photo;

- (void)removeAllPhotos;

- (void)downloadPhotosWithBlock:(BatchPhotoDownloadBlock)block;

@end
