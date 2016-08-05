//
//  PhotoDetailViewController.m
//  GCD_Example
//
//  Created by 雷亮 on 16/8/5.
//  Copyright © 2016年 Leiliang. All rights reserved.
//

#import "PhotoDetailViewController.h"
#import "PhotoHandler/PhotoHandler.h"
#import <QuartzCore/QuartzCore.h>

#define kScreenWidth [UIScreen mainScreen].bounds.size.width
#define kScreenHeight [UIScreen mainScreen].bounds.size.height

static CGFloat const kRetinaToEyeScaleFactor = 0.5f;
static CGFloat const kFaceBoundsToEyeScaleFactor = 4.f;

@interface PhotoDetailViewController () <UIScrollViewDelegate>

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (nonatomic, strong) UIImageView *imageView;

@end

@implementation PhotoDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    [self.scrollView addSubview:self.imageView];
    self.imageView.image = self.image;
    
    if (self.image.size.width < kScreenWidth && self.image.size.height < kScreenHeight) {
        _imageView.contentMode = UIViewContentModeCenter;
    } else {
        _imageView.contentMode = UIViewContentModeScaleAspectFit;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        UIImage *overlayImage = [self faceOverlayImageWithImage:self.image];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self fadeInNewImage:overlayImage];
        });
    });
}

#pragma mark -
#pragma mark - add eyes to face image
- (UIImage *)faceOverlayImageWithImage:(UIImage *)image {
    CIDetector* detector = [CIDetector detectorOfType:CIDetectorTypeFace
                                              context:nil
                                              options:@{CIDetectorAccuracy: CIDetectorAccuracyHigh}];
    CIImage* newImage = [CIImage imageWithCGImage:image.CGImage];
    
    NSArray *features = [detector featuresInImage:newImage];
    
    UIGraphicsBeginImageContext(image.size);
    CGRect imageRect = CGRectMake(0.0f, 0.0f, image.size.width, image.size.height);
    
    [image drawInRect:imageRect blendMode:kCGBlendModeNormal alpha:1.0f];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    for (CIFaceFeature *faceFeature in features) {
        CGRect faceRect = [faceFeature bounds];
        CGContextSaveGState(context);
        
        CGContextTranslateCTM(context, 0.0, imageRect.size.height);
        CGContextScaleCTM(context, 1.0f, -1.0f);
        
        if ([faceFeature hasLeftEyePosition]) {
            CGPoint leftEyePosition = [faceFeature leftEyePosition];
            CGFloat eyeWidth = faceRect.size.width / kFaceBoundsToEyeScaleFactor;
            CGFloat eyeHeight = faceRect.size.height / kFaceBoundsToEyeScaleFactor;
            CGRect eyeRect = CGRectMake(leftEyePosition.x - eyeWidth/2.0f,
                                        leftEyePosition.y - eyeHeight/2.0f,
                                        eyeWidth,
                                        eyeHeight);
            [self drawEyeBallForFrame:eyeRect];
        }
        
        if ([faceFeature hasRightEyePosition]) {
            CGPoint leftEyePosition = [faceFeature rightEyePosition];
            CGFloat eyeWidth = faceRect.size.width / kFaceBoundsToEyeScaleFactor;
            CGFloat eyeHeight = faceRect.size.height / kFaceBoundsToEyeScaleFactor;
            CGRect eyeRect = CGRectMake(leftEyePosition.x - eyeWidth / 2.0f,
                                        leftEyePosition.y - eyeHeight / 2.0f,
                                        eyeWidth,
                                        eyeHeight);
            [self drawEyeBallForFrame:eyeRect];
        }
        
        CGContextRestoreGState(context);
    }
    
    UIImage *overlayImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return overlayImage;
}

- (void)drawEyeBallForFrame:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextAddEllipseInRect(context, rect);
    CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
    CGContextFillPath(context);
    
    CGFloat x, y, eyeSizeWidth, eyeSizeHeight;
    eyeSizeWidth = rect.size.width * kRetinaToEyeScaleFactor;
    eyeSizeHeight = rect.size.height * kRetinaToEyeScaleFactor;
    
    x = arc4random_uniform((rect.size.width - eyeSizeWidth));
    y = arc4random_uniform((rect.size.height - eyeSizeHeight));
    x += rect.origin.x;
    y += rect.origin.y;
    
    CGFloat eyeSize = MIN(eyeSizeWidth, eyeSizeHeight);
    CGRect eyeBallRect = CGRectMake(x, y, eyeSize, eyeSize);
    CGContextAddEllipseInRect(context, eyeBallRect);
    CGContextSetFillColorWithColor(context, [UIColor blackColor].CGColor);
    CGContextFillPath(context);
}

- (void)fadeInNewImage:(UIImage *)image {
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    imageView.contentMode = self.imageView.contentMode;
    imageView.frame = self.imageView.bounds;
    imageView.alpha = 0.f;
    [self.imageView addSubview:imageView];
    
    [UIView animateWithDuration:0.75f animations:^{
        imageView.alpha = 1.0f;
    } completion:^(BOOL finished) {
        self.imageView.image = image;
        [imageView removeFromSuperview];
    }];
}

#pragma mark -
#pragma mark - scrollView protocal methods
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.imageView;
}

#pragma mark -
#pragma mark - getter methods
- (UIImageView *)imageView {
    if (!_imageView) {
        _imageView = [[UIImageView alloc] init];
        _imageView.frame = CGRectMake(0, 0, kScreenWidth, kScreenHeight);
        _imageView.contentMode = UIViewContentModeCenter;
    }
    return _imageView;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
