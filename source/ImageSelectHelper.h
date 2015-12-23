#import <Foundation/Foundation.h>
#import "XZImageCropperViewController.h"


@interface ImageSelectHelper : NSObject <
        UINavigationControllerDelegate,
        UIImagePickerControllerDelegate,
        XZImageCropperDelegate>
typedef void(^ImageSelectCallback)(NSString *data, UIImage *image);

- (void)setup:(UIViewController *)controller callback:(ImageSelectCallback)callback;
@end