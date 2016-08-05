//
//  Utils.h
//  GCD_Example
//
//  Created by 雷亮 on 16/8/5.
//  Copyright © 2016年 Leiliang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKitDefines.h>
#import <UIKit/UIKit.h>

/// 通知
static NSString *const kPhotoManagerAddedContentNotification = @"kPhotoManagerAddedContentNotification";
static NSString *const kPhotoManagerUpdateContentNotification = @"kPhotoManagerUpdateContentNotification";

/// image URL
static NSString *const kFirstImageURL = @"http://i.imgur.com/UvqEgCv.png";
static NSString *const kSecondImageURL = @"http://i.imgur.com/dZ5wRtb.png";
static NSString *const kThirdImageURL = @"http://i.imgur.com/tPzTg7A.jpg";

#ifndef Block_exe
#define Block_exe(block, ...) \
    if (block) { \
        block(__VA_ARGS__); \
    }
#endif

@interface Utils : NSObject

+ (UIColor *)defaultBackgroundColor;

@end
