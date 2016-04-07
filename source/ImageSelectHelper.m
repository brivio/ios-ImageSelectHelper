#import "ImageSelectHelper.h"
#import "LCActionSheet.h"
#import "MLSelectPhotoPickerViewController.h"
#import "MLSelectPhotoAssets.h"
#import "NSData+Extend.h"
#import <MobileCoreServices/MobileCoreServices.h>

@implementation ImageSelectHelper {
    UIViewController *_controller;
    ImageSelectCallback _callback;
    UIImagePickerController *_imagePicker;
    NSMutableArray *multiAssets;
}

- (void)setup:(UIViewController *)context callback:(ImageSelectCallback)callback {
    _controller = context;
    _callback = callback;

    LCActionSheet *sheet = [LCActionSheet sheetWithTitle:nil buttonTitles:@[@"拍照", @"从相册选择"] redButtonIndex:-1 clicked:^(NSInteger buttonIndex) {
        if (buttonIndex == 0) {
            // 拍照
            if ([self isCameraAvailable] && [self doesCameraSupportTakingPhotos]) {
                _imagePicker = [[UIImagePickerController alloc] init];
                _imagePicker.navigationBar.tintColor = [UIColor whiteColor];
                _imagePicker.navigationBar.titleTextAttributes = @{
                        NSFontAttributeName : [UIFont boldSystemFontOfSize:18],
                        NSForegroundColorAttributeName : [UIColor whiteColor],
                };
                _imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
                if ([self isFrontCameraAvailable]) {
                    _imagePicker.cameraDevice = UIImagePickerControllerCameraDeviceFront;
                }
                NSMutableArray *mediaTypes = [[NSMutableArray alloc] init];
                [mediaTypes addObject:(__bridge NSString *) kUTTypeImage];
                _imagePicker.mediaTypes = mediaTypes;
                _imagePicker.delegate = self;
                [_controller presentViewController:_imagePicker animated:YES completion:^() {
                }];
            }
        } else if (buttonIndex == 1) {
            // 从相册中选取
            if (_maxCount > 0) {
                // 创建控制器
                MLSelectPhotoPickerViewController *pickerVc = [[MLSelectPhotoPickerViewController alloc] init];
                // 默认显示相册里面的内容SavePhotos
                pickerVc.selectPickers = multiAssets;
                pickerVc.maxCount = _maxCount;
                pickerVc.status = PickerViewShowStatusCameraRoll;
                [pickerVc showPickerVc:context];
                pickerVc.callBack = ^(NSArray *assets) {
                    [assets enumerateObjectsUsingBlock:^(MLSelectPhotoAssets *asset, NSUInteger idx, BOOL *stop) {
                        [self compress:[MLSelectPhotoPickerViewController getImageWithImageObj:asset]];
                    }];
                };
            } else if ([self isPhotoLibraryAvailable]) {
                _imagePicker = [[UIImagePickerController alloc] init];
                _imagePicker.navigationBar.tintColor = [UIColor whiteColor];
                _imagePicker.navigationBar.titleTextAttributes = @{
                        NSFontAttributeName : [UIFont boldSystemFontOfSize:18],
                        NSForegroundColorAttributeName : [UIColor whiteColor],
                };
                _imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
                NSMutableArray *mediaTypes = [[NSMutableArray alloc] init];
                [mediaTypes addObject:(__bridge NSString *) kUTTypeImage];
                _imagePicker.mediaTypes = mediaTypes;
                _imagePicker.delegate = self;
                [_controller presentViewController:_imagePicker animated:YES completion:^() {
                }];
            }
        }
    }];

    [sheet show];
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [picker dismissViewControllerAnimated:YES completion:^() {
        UIImage *portraitImg = info[@"UIImagePickerControllerOriginalImage"];
        portraitImg = [self imageByScalingToMaxSize:portraitImg];
        if (self.isCrop) {
            CGFloat width = _controller.view.frame.size.width;
            CGFloat height = _controller.view.frame.size.height;
            CGFloat top = (height - 200.0f) / 2.0f;
            CGFloat left = (width - 200.0f) / 2.0f;
            // 裁剪
            XZImageCropperViewController *imgEditorVC = [[XZImageCropperViewController alloc] initWithImage:portraitImg cropFrame:CGRectMake(left, top, 200.0f, 200.0f) limitScaleRatio:3];
            imgEditorVC.delegate = self;
            [_controller presentViewController:imgEditorVC animated:YES completion:^() {
            }];
        } else {
            [self compress:portraitImg];
        }
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:^() {
    }];
}

#pragma mark XZImageCropperDelegate

- (void)compress:(UIImage *)img {
    NSData *data = UIImageJPEGRepresentation(img, 0.5);

    while ([data length] / 1024 > 500) {
        data = UIImageJPEGRepresentation(img, 0.5);
    }
    _callback([data base64_encode], img);
}

- (void)imageCropper:(XZImageCropperViewController *)cropperViewController didFinished:(UIImage *)editedImage {
    [self compress:editedImage];
    [cropperViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)imageCropperDidCancel:(XZImageCropperViewController *)cropperViewController {
    [cropperViewController dismissViewControllerAnimated:YES completion:^{
    }];
}

#pragma mark 摄像头

- (BOOL)isCameraAvailable {
    return [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera];
}

- (BOOL)isFrontCameraAvailable {
    return [UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceFront];
}

- (BOOL)doesCameraSupportTakingPhotos {
    return [self cameraSupportsMedia:(__bridge NSString *) kUTTypeImage sourceType:UIImagePickerControllerSourceTypeCamera];
}

- (BOOL)isPhotoLibraryAvailable {
    return [UIImagePickerController isSourceTypeAvailable:
            UIImagePickerControllerSourceTypePhotoLibrary];
}

- (BOOL)cameraSupportsMedia:(NSString *)paramMediaType sourceType:(UIImagePickerControllerSourceType)paramSourceType {
    __block BOOL result = NO;
    if ([paramMediaType length] == 0) {
        return NO;
    }
    NSArray *availableMediaTypes = [UIImagePickerController availableMediaTypesForSourceType:paramSourceType];
    [availableMediaTypes enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSString *mediaType = (NSString *) obj;
        if ([mediaType isEqualToString:paramMediaType]) {
            result = YES;
            *stop = YES;
        }
    }];
    return result;
}

#pragma mark image scale utility
#define ORIGINAL_MAX_WIDTH 640.0f

- (UIImage *)imageByScalingToMaxSize:(UIImage *)sourceImage {
    if (sourceImage.size.width < ORIGINAL_MAX_WIDTH) return sourceImage;
    CGFloat btWidth;
    CGFloat btHeight;
    if (sourceImage.size.width > sourceImage.size.height) {
        btHeight = ORIGINAL_MAX_WIDTH;
        btWidth = sourceImage.size.width * (ORIGINAL_MAX_WIDTH / sourceImage.size.height);
    } else {
        btWidth = ORIGINAL_MAX_WIDTH;
        btHeight = sourceImage.size.height * (ORIGINAL_MAX_WIDTH / sourceImage.size.width);
    }
    CGSize targetSize = CGSizeMake(btWidth, btHeight);
    return [self imageByScalingAndCroppingForSourceImage:sourceImage targetSize:targetSize];
}

- (UIImage *)imageByScalingAndCroppingForSourceImage:(UIImage *)sourceImage targetSize:(CGSize)targetSize {
    UIImage *newImage = nil;
    CGSize imageSize = sourceImage.size;
    CGFloat width = imageSize.width;
    CGFloat height = imageSize.height;
    CGFloat targetWidth = targetSize.width;
    CGFloat targetHeight = targetSize.height;
    CGFloat scaleFactor;
    CGFloat scaledWidth = targetWidth;
    CGFloat scaledHeight = targetHeight;
    CGPoint thumbnailPoint = CGPointMake(0.0, 0.0);
    if (!CGSizeEqualToSize(imageSize, targetSize)) {
        CGFloat widthFactor = targetWidth / width;
        CGFloat heightFactor = targetHeight / height;

        if (widthFactor > heightFactor)
            scaleFactor = widthFactor; // scale to fit height
        else
            scaleFactor = heightFactor; // scale to fit width
        scaledWidth = width * scaleFactor;
        scaledHeight = height * scaleFactor;

        // center the image
        if (widthFactor > heightFactor) {
            thumbnailPoint.y = (CGFloat) ((targetHeight - scaledHeight) * 0.5);
        }
        else if (widthFactor < heightFactor) {
            thumbnailPoint.x = (CGFloat) ((targetWidth - scaledWidth) * 0.5);
        }
    }
    UIGraphicsBeginImageContext(targetSize); // this will crop
    CGRect thumbnailRect = CGRectZero;
    thumbnailRect.origin = thumbnailPoint;
    thumbnailRect.size.width = scaledWidth;
    thumbnailRect.size.height = scaledHeight;

    [sourceImage drawInRect:thumbnailRect];

    newImage = UIGraphicsGetImageFromCurrentImageContext();
    if (newImage == nil) NSLog(@"could not scale image");
    UIGraphicsEndImageContext();
    return newImage;
}

@end