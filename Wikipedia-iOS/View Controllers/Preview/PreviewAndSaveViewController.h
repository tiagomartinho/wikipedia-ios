//  Created by Monte Hurd on 2/27/14.

#import <UIKit/UIKit.h>
#import "MWNetworkOp.h"
#import "CaptchaViewController.h"

@class NSManagedObjectID;

@interface PreviewAndSaveViewController : UIViewController <NetworkOpDelegate, UITextFieldDelegate, CaptchaViewControllerRefresh, UIScrollViewDelegate>

@property (strong, nonatomic) NSManagedObjectID *sectionID;
@property (strong, nonatomic) NSString *wikiText;

-(void)reloadCaptchaPushed:(id)sender;

@end
