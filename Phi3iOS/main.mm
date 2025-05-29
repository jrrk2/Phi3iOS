#import <UIKit/UIKit.h>
#import "ChatViewController.h"
#import "LoadingViewController.h"
#include "ort_genai_c.h"  // Include ONNX Runtime GenAI

@interface AppDelegate : UIResponder <UIApplicationDelegate, LoadingViewControllerDelegate>
@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) LoadingViewController *loadingVC;
@property (strong, nonatomic) NSString *modelPath;
@end

@implementation AppDelegate

void listBundleContents() {
    NSString* bundlePath = [[NSBundle mainBundle] resourcePath];
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSError* error = nil;
    
    NSArray* contents = [fileManager subpathsOfDirectoryAtPath:bundlePath
                                                         error:&error];
    if (error) {
        NSLog(@"Error: %@", error.localizedDescription);
        return;
    }
    
    NSLog(@"Bundle contents:");
    for (NSString* path in [contents sortedArrayUsingSelector:@selector(compare:)]) {
        NSLog(@"  %@", path);
    }
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    // Show loading screen first
    self.loadingVC = [[LoadingViewController alloc] init];
    self.loadingVC.delegate = self;
    
    self.window.rootViewController = self.loadingVC;
    [self.window makeKeyAndVisible];
    
    // Start the model loading process
    [self startModelInitialization];
    
    NSLog(@"🚀 PHI3 iOS App Started - Loading AI Model...");
    
    return YES;
}

- (void)startModelInitialization {
    // Update progress immediately
    [self.loadingVC updateProgress:0.1 withStatus:@"Checking system memory..."];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.loadingVC updateProgress:0.3 withStatus:@"Locating AI model files..."];
        });
        
        // Step 3: Find model directory
        NSString* modelDir = [[NSBundle mainBundle] pathForResource:@"cpu-int4-rtn-block-32-acc-level-4"
                                                             ofType:nil];
        if (!modelDir) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.loadingVC showError:@"❌ AI model not found in bundle"];
            });
            return;
        }
        
        self.modelPath = modelDir;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.loadingVC updateProgress:0.5 withStatus:@"Initializing ONNX Runtime..."];
        });
        
        // Step 4: Test model loading with progress updates
        [self testModelLoadingWithProgress];
    });
}

- (void)testModelLoadingWithProgress {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        extern int test_phi3_main(const char *);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.loadingVC updateProgress:0.7 withStatus:@"Loading neural network weights..."];
        });
        
        // Small delay to show progress
        [NSThread sleepForTimeInterval:0.5];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.loadingVC updateProgress:0.85 withStatus:@"Running model validation..."];
        });
        
        // Actually test the model
        const char* modelPath = [self.modelPath UTF8String];
        int result = test_phi3_main(modelPath);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (result == 0) {
                [self.loadingVC updateProgress:0.95 withStatus:@"Model loaded successfully!"];
                
                // Final delay before completing
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self.loadingVC completeLoading];
                });
            } else {
                [self.loadingVC showError:@"❌ Failed to initialize AI model"];
            }
        });
        
        if (result == 0) {
            NSLog(@"✅ PHI3 model loaded successfully!");
        } else {
            NSLog(@"❌ PHI3 model failed to load");
        }
    });
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    NSLog(@"⚠️ System memory warning received");
}

#pragma mark - LoadingViewControllerDelegate

- (void)loadingDidComplete {
    // Transition to main chat interface
    ChatViewController *chatVC = [[ChatViewController alloc] init];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:chatVC];
    
    // Smooth transition animation
    [UIView transitionWithView:self.window
                      duration:0.5
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{
        self.window.rootViewController = navController;
    } completion:^(BOOL finished) {
        self.loadingVC = nil; // Clean up
        NSLog(@"✅ Transitioned to chat interface");
     }];
}

@end

int main(int argc, char * argv[]) {
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
