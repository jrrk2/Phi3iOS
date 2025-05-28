#import <UIKit/UIKit.h>

@protocol LoadingViewControllerDelegate <NSObject>
- (void)loadingDidComplete;
@end

@interface LoadingViewController : UIViewController

@property (weak, nonatomic) id<LoadingViewControllerDelegate> delegate;

// UI Elements
@property (strong, nonatomic) UIImageView *logoImageView;
@property (strong, nonatomic) UILabel *titleLabel;
@property (strong, nonatomic) UILabel *statusLabel;
@property (strong, nonatomic) UIProgressView *progressView;
@property (strong, nonatomic) UIActivityIndicatorView *spinner;

// Progress control
- (void)updateProgress:(float)progress withStatus:(NSString *)status;
- (void)showError:(NSString *)errorMessage;
- (void)completeLoading;

@end
