#import "LoadingViewController.h"

@interface LoadingViewController ()
@property (nonatomic) BOOL hasCompletedLoading;
@end

@implementation LoadingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Set up gradient background
    [self setupGradientBackground];
    [self setupUI];
    [self startLoadingAnimation];
}

- (void)setupGradientBackground {
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.frame = self.view.bounds;
    
    // Beautiful gradient from dark blue to purple
    gradientLayer.colors = @[
        (id)[UIColor colorWithRed:0.1 green:0.1 blue:0.3 alpha:1.0].CGColor,
        (id)[UIColor colorWithRed:0.2 green:0.1 blue:0.4 alpha:1.0].CGColor,
        (id)[UIColor colorWithRed:0.3 green:0.2 blue:0.5 alpha:1.0].CGColor
    ];
    
    gradientLayer.startPoint = CGPointMake(0, 0);
    gradientLayer.endPoint = CGPointMake(1, 1);
    
    [self.view.layer insertSublayer:gradientLayer atIndex:0];
}

- (void)setupUI {
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    
    // Create logo/icon (using SF Symbol for now)
    self.logoImageView = [[UIImageView alloc] init];
    self.logoImageView.translatesAutoresizingMaskIntoConstraints = NO;
    
    UIImage *phi3Icon = [UIImage imageNamed:@"AppIcon.png"]; // Use one of your generated app icon sizes
    
    // Option 2: Or create a separate launch icon in Assets.xcassets
    // UIImage *phi3Icon = [UIImage imageNamed:@"LaunchIcon"]; // If you create a separate asset
    
    self.logoImageView.image = phi3Icon;
    // Remove the tintColor line since your icon has its own colors
    // self.logoImageView.tintColor = [UIColor whiteColor]; // Comment out or remove this line
    self.logoImageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.view addSubview:self.logoImageView];
    
    // Title label
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.titleLabel.text = @"PHI3 AI Assistant";
    self.titleLabel.font = [UIFont systemFontOfSize:32 weight:UIFontWeightLight];
    self.titleLabel.textColor = [UIColor whiteColor];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.titleLabel];
    
    // Status label
    self.statusLabel = [[UILabel alloc] init];
    self.statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.statusLabel.text = @"Initializing AI model...";
    self.statusLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightRegular];
    self.statusLabel.textColor = [UIColor colorWithWhite:0.9 alpha:1.0];
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.statusLabel];
    
    // Progress view
    self.progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    self.progressView.translatesAutoresizingMaskIntoConstraints = NO;
    self.progressView.progressTintColor = [UIColor colorWithRed:0.3 green:0.7 blue:1.0 alpha:1.0];
    self.progressView.trackTintColor = [UIColor colorWithWhite:1.0 alpha:0.2];
    self.progressView.layer.cornerRadius = 2;
    self.progressView.clipsToBounds = YES;
    [self.view addSubview:self.progressView];
    
    // Activity indicator (for indeterminate progress)
    self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    self.spinner.translatesAutoresizingMaskIntoConstraints = NO;
    self.spinner.color = [UIColor whiteColor];
    [self.view addSubview:self.spinner];
    
    [self setupConstraints];
}

- (void)setupConstraints {
    [NSLayoutConstraint activateConstraints:@[
        // Logo
        [self.logoImageView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.logoImageView.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor constant:-80],
        [self.logoImageView.widthAnchor constraintEqualToConstant:100],
        [self.logoImageView.heightAnchor constraintEqualToConstant:100],
        
        // Title
        [self.titleLabel.topAnchor constraintEqualToAnchor:self.logoImageView.bottomAnchor constant:20],
        [self.titleLabel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:40],
        [self.titleLabel.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-40],
        
        // Status
        [self.statusLabel.topAnchor constraintEqualToAnchor:self.titleLabel.bottomAnchor constant:40],
        [self.statusLabel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:40],
        [self.statusLabel.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-40],
        
        // Progress bar
        [self.progressView.topAnchor constraintEqualToAnchor:self.statusLabel.bottomAnchor constant:20],
        [self.progressView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:60],
        [self.progressView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-60],
        [self.progressView.heightAnchor constraintEqualToConstant:4],
        
        // Spinner
        [self.spinner.topAnchor constraintEqualToAnchor:self.progressView.bottomAnchor constant:30],
        [self.spinner.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor]
    ]];
}

- (void)startLoadingAnimation {
    [self.spinner startAnimating];
    
    // Add gentle pulsing animation to logo
    CABasicAnimation *pulseAnimation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    pulseAnimation.duration = 2.0;
    pulseAnimation.fromValue = @1.0;
    pulseAnimation.toValue = @1.1;
    pulseAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    pulseAnimation.autoreverses = YES;
    pulseAnimation.repeatCount = HUGE_VALF;
    
    [self.logoImageView.layer addAnimation:pulseAnimation forKey:@"pulse"];
}

- (void)updateProgress:(float)progress withStatus:(NSString *)status {
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:0.3 animations:^{
            self.progressView.progress = progress;
        }];
        
        if (status) {
            self.statusLabel.text = status;
        }
        
        // Add a subtle bounce when reaching certain milestones
        if (progress >= 0.25 && progress < 0.3) {
            [self addBounceAnimation];
        }
    });
}

- (void)addBounceAnimation {
    CAKeyframeAnimation *bounce = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
    bounce.values = @[@1.0, @1.05, @1.0];
    bounce.duration = 0.3;
    bounce.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    
    [self.progressView.layer addAnimation:bounce forKey:@"bounce"];
}

- (void)showError:(NSString *)errorMessage {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.spinner stopAnimating];
        self.statusLabel.text = errorMessage;
        self.statusLabel.textColor = [UIColor colorWithRed:1.0 green:0.4 blue:0.4 alpha:1.0];
        
        // Show retry option after 3 seconds
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (!self.hasCompletedLoading) {
                self.statusLabel.text = @"Tap to retry...";
                
                // Add tap gesture
                UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(retryLoading)];
                [self.view addGestureRecognizer:tapGesture];
            }
        });
    });
}

- (void)retryLoading {
    // Reset UI
    self.statusLabel.textColor = [UIColor colorWithWhite:0.9 alpha:1.0];
    self.statusLabel.text = @"Retrying...";
    self.progressView.progress = 0.0;
    [self.spinner startAnimating];
    
    // Remove tap gesture
    for (UIGestureRecognizer *gesture in self.view.gestureRecognizers) {
        [self.view removeGestureRecognizer:gesture];
    }
    
    // Notify delegate to retry
    if (self.delegate && [self.delegate respondsToSelector:@selector(loadingDidComplete)]) {
        [self.delegate loadingDidComplete];
    }
}

- (void)completeLoading {
    if (self.hasCompletedLoading) return;
    self.hasCompletedLoading = YES;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.spinner stopAnimating];
        self.statusLabel.text = @"Ready!";
        self.progressView.progress = 1.0;
        
        // Success animation
        CABasicAnimation *checkmarkAnimation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
        checkmarkAnimation.fromValue = @1.0;
        checkmarkAnimation.toValue = @1.2;
        checkmarkAnimation.duration = 0.3;
        checkmarkAnimation.autoreverses = YES;
        
        [self.logoImageView.layer addAnimation:checkmarkAnimation forKey:@"success"];
        
        // Transition to main app after a brief delay
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (self.delegate && [self.delegate respondsToSelector:@selector(loadingDidComplete)]) {
                [self.delegate loadingDidComplete];
            }
        });
    });
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.spinner stopAnimating];
}

@end
