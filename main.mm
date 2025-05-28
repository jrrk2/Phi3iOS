#import <UIKit/UIKit.h>
#include "ort_genai_c.h"  // Include ONNX Runtime GenAI

@interface AppDelegate : UIResponder <UIApplicationDelegate>
@property (strong, nonatomic) UIWindow *window;
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    // Create a simple view controller for testing
    UIViewController *vc = [[UIViewController alloc] init];
    vc.view.backgroundColor = [UIColor systemBackgroundColor];
    
    // Add a label to show it's working
    UILabel *label = [[UILabel alloc] init];
    label.text = @"Phi-3 iOS App Ready";
    label.textAlignment = NSTextAlignmentCenter;
    label.translatesAutoresizingMaskIntoConstraints = NO;
    [vc.view addSubview:label];
    
    [NSLayoutConstraint activateConstraints:@[
        [label.centerXAnchor constraintEqualToAnchor:vc.view.centerXAnchor],
        [label.centerYAnchor constraintEqualToAnchor:vc.view.centerYAnchor]
    ]];
    
    self.window.rootViewController = vc;
    [self.window makeKeyAndVisible];
    
    // TODO: Initialize ONNX Runtime GenAI here
    // Example: OgaModel* model = OgaCreateModel("path/to/model");
    NSLog(@"Phi-3 iOS App Started - Ready for GenAI integration");
    
    return YES;
}

@end

int main(int argc, char * argv[]) {
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
