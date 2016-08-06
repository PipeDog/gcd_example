//
//  ViewController.m
//  GCD_Example
//
//  Created by 雷亮 on 16/8/5.
//  Copyright © 2016年 Leiliang. All rights reserved.
//

#import "ViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "PhotoDetailViewController.h"
#import "ELCImagePickerController.h"
#import "Utils.h"
#import "PhotoHandler.h"

static NSInteger const kCellImageViewTag = 3;
static CGFloat const kBackgroundImageAlpha = 0.1f;
static NSString *const reUse = @"reUse";

@interface ViewController () <UICollectionViewDelegate, UICollectionViewDataSource, ELCImagePickerControllerDelegate, UIActionSheetDelegate>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (nonatomic, strong) ALAssetsLibrary *library;
@property (nonatomic, strong) UIImageView *backgroundImageView;

@end

@implementation ViewController

/*
 gcd 深入理解1:
 http://www.cocoachina.com/industry/20140428/8248.html
 gcd 深入理解2:
 http://www.cocoachina.com/industry/20140515/8433.html
 */

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self updatePrompt];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.library = [[ALAssetsLibrary alloc] init];
    
    self.collectionView.backgroundView = self.backgroundImageView;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contentChangedNotification:) name:kPhotoManagerAddedContentNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contentChangedNotification:) name:kPhotoManagerUpdateContentNotification object:nil];
}

#pragma mark -
#pragma mark - privite methods
- (void)contentChangedNotification:(NSNotification *)notification {
    [self.collectionView reloadData];
    [self updatePrompt];
}

- (void)updatePrompt {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if ([[PhotoHandler shareInstance] photos].count) {
            self.navigationItem.prompt = nil;
        } else {
            self.navigationItem.prompt = @"请添加图片";
        }
    });
}

#pragma mark -
#pragma mark - collectionView protocol methods
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [[PhotoHandler shareInstance] photos].count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reUse forIndexPath:indexPath];
    UIImageView *imageView = [cell viewWithTag:kCellImageViewTag];
    Photo *photo = [[PhotoHandler shareInstance] photos][indexPath.row];
    switch (photo.status) {
        case PhotoStatusDownloading: {
            imageView.image = [UIImage imageNamed:@"photoDownloading.png"];
            break;
        }
        case PhotoStatusSuccess: {
            imageView.image = [photo thumbnail];
            break;
        }
        case PhotoStatusFailed: {
            imageView.image = [UIImage imageNamed:@"photoDownloadError.png"];
            break;
        }
    }
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    Photo *photo = [[PhotoHandler shareInstance] photos][indexPath.row];
    switch (photo.status) {
        case PhotoStatusDownloading: {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Downloading" message:@"the image is downloading" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [alertView show];
            break;
        }
        case PhotoStatusSuccess: {
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
            PhotoDetailViewController *photoDetailVC = [storyboard instantiateViewControllerWithIdentifier:@"PhotoDetailVC"];
            photoDetailVC.image = [photo image];
            [self.navigationController pushViewController:photoDetailVC animated:YES];
            break;
        }
        case PhotoStatusFailed: {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Failed" message:@"the image is failed" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [alertView show];
            break;
        }
    }
}

#pragma mark -
#pragma mark - elc image picker controller protocol methods
- (void)elcImagePickerController:(ELCImagePickerController *)picker didFinishPickingMediaWithInfo:(NSArray *)info {
    for (NSDictionary *dic in info) {
        [self.library assetForURL:dic[UIImagePickerControllerReferenceURL] resultBlock:^(ALAsset *asset) {
            Photo *photo = [[Photo alloc] initWithAsset:asset];
            [[PhotoHandler shareInstance] addPhoto:photo];
        } failureBlock:^(NSError *error) {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"权限被拒绝" message:@"" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [alertView show];
        }];
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)elcImagePickerControllerDidCancel:(ELCImagePickerController *)picker {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark -
#pragma mark - IBAction methods
- (IBAction)addPhotoAction:(id)sender {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"get photos from" delegate:self cancelButtonTitle:@"cancel" destructiveButtonTitle:nil otherButtonTitles:@"相册", @"网络下载", @"dispatch_semaphore", @"dispatch_source", nil];
    [actionSheet showInView:self.view];
}

- (IBAction)removeSelectsPhotos:(id)sender {
    [[PhotoHandler shareInstance] removeAllPhotos];
    [self.collectionView reloadData];
}

#pragma mark -
#pragma mark - actionSheet protocol methods
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) { // 相册
        ELCImagePickerController *imagePickerVC = [[ELCImagePickerController alloc] init];
        imagePickerVC.imagePickerDelegate = self;
        [self presentViewController:imagePickerVC animated:YES completion:nil];
    } else if (buttonIndex == 1) { // 网络
        [[PhotoHandler shareInstance] downloadPhotosWithBlock:^(NSError *error) {
            NSString *message = error ? error.localizedDescription: @"image download finished";
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"下载完成" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [alertView show];
        }];
    } else if (buttonIndex == 2) { // dispatch_semaphore测试
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        NSURL *URL = [NSURL URLWithString:kFirstImageURL];
        __unused Photo *photo = [[Photo alloc] initWithURL:URL withCompletionBlock:^(UIImage *image, NSError *error) {
            if (error) {
                NSLog(@"error : %@", error.localizedDescription);
            }
            dispatch_semaphore_signal(semaphore);
            NSLog(@"image : %@", image);
        }];
        dispatch_time_t timeout_time = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC));
        // dispatch_semaphore_wait 返回值为0成功，非0超时
        long semaphore_value = dispatch_semaphore_wait(semaphore, timeout_time);
        if (semaphore_value) {
            NSLog(@"time out ... URL: %@", URL.absoluteString);
        }
    } else if (buttonIndex == 3) {
        
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

    }
}

#pragma mark -
#pragma mark - getter methods
- (UIImageView *)backgroundImageView {
    if (!_backgroundImageView) {
        _backgroundImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"eye.png"]];
        _backgroundImageView.alpha = kBackgroundImageAlpha;
        _backgroundImageView.contentMode = UIViewContentModeCenter;
    }
    return _backgroundImageView;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
