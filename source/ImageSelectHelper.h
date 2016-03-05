#import <Foundation/Foundation.h>
#import "XZImageCropperViewController.h"


@interface ImageSelectHelper : UIViewController <
        UINavigationControllerDelegate,
        UIImagePickerControllerDelegate,
        XZImageCropperDelegate>
typedef void(^ImageSelectCallback)(NSString *data, UIImage *image);

@property BOOL isCrop;
@property NSInteger maxCount;

- (void)setup:(UIViewController *)controller callback:(ImageSelectCallback)callback;
@end