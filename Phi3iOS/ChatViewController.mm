#import "ChatViewController.h"
#import "SettingsViewController.h"
#import "MemoryManager.h"
#import "MemoryProfiler.h"
#include "ort_genai_c.h"
#include <string>
#include <cstdint>
#include <unistd.h>

// Enhanced C++ function declarations with streaming support
extern "C" {
    int test_phi3_main(const char *);
    void cancelPhi3Generation();
}

std::string generatePhi3ResponseStreaming(const char* user_input, const char* model_path, 
                                        int target_tokens, int max_total_tokens,
                                        void(^tokenCallback)(const char* token, bool isComplete));

std::string generatePhi3ResponseContinuation(const char* user_input, const char* previous_response, 
                                           const char* model_path, int max_tokens);

// Global cancellation flag for C++ code
static volatile bool g_should_cancel_generation = false;

// C++ cancellation function
extern "C" void cancelPhi3Generation() {
    g_should_cancel_generation = true;
}

@interface ChatViewController () <SettingsDelegate>
// Basic properties
@property (strong, nonatomic) NSString *modelPath;
@property (nonatomic) CGFloat keyboardHeight;
@property (nonatomic) BOOL shouldStopGeneration;

// Auto-continue properties
@property (strong, nonatomic) NSString *fullResponse;
@property (nonatomic) NSInteger totalTokensGenerated;
@property (nonatomic) NSInteger maxResponseTokens;
@property (nonatomic) BOOL isAutoGenerating;
@property (strong, nonatomic) NSTimer *autoScrollTimer;

// Memory optimization
@property (strong, nonatomic) dispatch_queue_t inferenceQueue;

// Smart stopping
@property (strong, nonatomic) NSString *lastSentence;
@property (nonatomic) NSInteger consecutiveIncompleteTokens;

// Continue functionality
@property (nonatomic) BOOL shouldShowContinueButton;

// Keyboard handling
@property (strong, nonatomic) NSLayoutConstraint *inputBottomConstraint;

// ORIENTATION HANDLING - New constraint properties
@property (strong, nonatomic) NSLayoutConstraint *chatTopConstraint;
@property (strong, nonatomic) NSLayoutConstraint *chatLeadingConstraint;
@property (strong, nonatomic) NSLayoutConstraint *chatTrailingConstraint;
@property (strong, nonatomic) NSLayoutConstraint *inputHeightConstraint;

@end

@implementation ChatViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    self.title = @"PHI3 Smart Chat";
    
    // Initialize properties
    self.maxResponseTokens = 200;
    self.totalTokensGenerated = 0;
    self.consecutiveIncompleteTokens = 0;
    self.shouldStopGeneration = NO;
    self.shouldShowContinueButton = NO;
    
    // Create dedicated inference queue
    self.inferenceQueue = dispatch_queue_create("phi3.inference", 
                                               DISPATCH_QUEUE_SERIAL);
    
    // Get model path
    NSString* modelDir = [[NSBundle mainBundle] pathForResource:@"cpu-int4-rtn-block-32-acc-level-4"
                                                         ofType:nil];
    self.modelPath = modelDir;
    
    // Setup memory management
    [[MemoryManager shared] preAllocateForPHI3Model];
    [[MemoryProfiler shared] startProfiling];
    
    // Add navigation buttons
    UIBarButtonItem *flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    // Settings button (right side)
    UIBarButtonItem *settingsButton = [[UIBarButtonItem alloc] 
                                      initWithTitle:@"Settings" 
                                      style:UIBarButtonItemStylePlain 
                                      target:self 
                                      action:@selector(settingsButtonTapped)];
    
    // Clear button (also right side, next to settings)
    UIBarButtonItem *clearButton = [[UIBarButtonItem alloc]
                                   initWithTitle:@"Clear"
                                   style:UIBarButtonItemStylePlain
                                   target:self
                                   action:@selector(clearButtonTapped)];
    clearButton.tintColor = [UIColor systemRedColor];
    
    // Set both buttons on the right side
    self.navigationItem.rightBarButtonItems = @[settingsButton, clearButton];
    
    // Continue button (left side, initially disabled)
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]
                                            initWithTitle:@"Continue"
                                            style:UIBarButtonItemStylePlain
                                            target:self
                                            action:@selector(continueGeneration)];
    self.navigationItem.leftBarButtonItem.enabled = NO;

    NSMutableArray *rightButtons = [self.navigationItem.rightBarButtonItems mutableCopy];

    self.navigationItem.rightBarButtonItems = rightButtons;

    [self setupUI];
    [self setupKeyboardNotifications];
    [self setupMemoryMonitoring];
    [self setupOrientationHandling]; // NEW - Add orientation handling
    
    // Add welcome message
    [self appendToChatLog:@"PHI3 Smart Chat Ready! Tap 'Clear' to start a fresh conversation anytime." fromUser:NO];
}

// KEEP the viewWillTransitionToSize method (it's working)
- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    NSLog(@"🔄 viewWillTransitionToSize: %@", NSStringFromCGSize(size));
    
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self updateLayoutForSize:size];
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self scrollToBottom];
        });
    }];
}

// FIXED setupOrientationHandling - enable device notifications
- (void)setupOrientationHandling {
    NSLog(@"🔧 Setting up orientation handling...");
    
    // CRITICAL: Enable device orientation notifications
    if (![UIDevice currentDevice].isGeneratingDeviceOrientationNotifications) {
        NSLog(@"⚠️ Device orientation notifications disabled - enabling...");
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(orientationDidChange:)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];
    
    NSLog(@"✅ Orientation observer added");
}

// ENHANCED orientationDidChange with better logic
- (void)orientationDidChange:(NSNotification *)notification {
    UIDeviceOrientation deviceOrientation = [[UIDevice currentDevice] orientation];
    
    NSLog(@"🔄 Device orientation changed to: %ld", (long)deviceOrientation);
    
    // Filter out invalid orientations
    if (deviceOrientation == UIDeviceOrientationUnknown || 
        deviceOrientation == UIDeviceOrientationFaceUp || 
        deviceOrientation == UIDeviceOrientationFaceDown) {
        NSLog(@"⚠️ Ignoring invalid orientation: %ld", (long)deviceOrientation);
        return;
    }
    
    // Calculate expected view size based on device orientation
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    CGSize expectedSize;
    
    if (deviceOrientation == UIDeviceOrientationLandscapeLeft || 
        deviceOrientation == UIDeviceOrientationLandscapeRight) {
        // Landscape
        expectedSize = CGSizeMake(MAX(screenBounds.size.width, screenBounds.size.height),
                                 MIN(screenBounds.size.width, screenBounds.size.height));
    } else {
        // Portrait
        expectedSize = CGSizeMake(MIN(screenBounds.size.width, screenBounds.size.height),
                                 MAX(screenBounds.size.width, screenBounds.size.height));
    }
    
    NSLog(@"📐 Expected view size for orientation: %@", NSStringFromCGSize(expectedSize));
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateLayoutForSize:expectedSize];
    });
}

// ENHANCED updateLayoutForSize with debug info
- (void)updateLayoutForSize:(CGSize)size {
    BOOL isLandscape = size.width > size.height;
    CGSize currentSize = self.view.bounds.size;
    
    NSLog(@"📐 updateLayoutForSize:");
    NSLog(@"   Target size: %@", NSStringFromCGSize(size));
    NSLog(@"   Current size: %@", NSStringFromCGSize(currentSize));
    NSLog(@"   Is landscape: %@", isLandscape ? @"YES" : @"NO");
    
    // Check if constraints exist
    if (!self.chatTopConstraint || !self.chatLeadingConstraint || 
        !self.chatTrailingConstraint || !self.inputHeightConstraint) {
        NSLog(@"❌ Constraint references missing - skipping layout update");
        return;
    }
    
    // Only update if orientation actually changed
    BOOL currentIsLandscape = currentSize.width > currentSize.height;
    if (isLandscape == currentIsLandscape) {
        NSLog(@"📐 No orientation change detected - skipping");
        return;
    }
    
    NSLog(@"📐 Applying %@ layout", isLandscape ? @"landscape" : @"portrait");
    
    // Adjust constraints based on orientation
    if (isLandscape) {
        // Landscape: More horizontal space, less vertical space
        self.chatTopConstraint.constant = 4;
        self.chatLeadingConstraint.constant = 12;
        self.chatTrailingConstraint.constant = -12;
        self.inputHeightConstraint.constant = 50;
    } else {
        // Portrait: Standard spacing
        self.chatTopConstraint.constant = 8;
        self.chatLeadingConstraint.constant = 8;
        self.chatTrailingConstraint.constant = -8;
        self.inputHeightConstraint.constant = 60;
    }
    
    // Update fonts
    [self updateFontsForOrientation:isLandscape];
    
    // Animate the changes
    [UIView animateWithDuration:0.3 animations:^{
        [self.view layoutIfNeeded];
    } completion:^(BOOL finished) {
        NSLog(@"✅ Layout animation completed");
        [self scrollToBottom];
    }];
}

// NEW - Update fonts based on orientation
- (void)updateFontsForOrientation:(BOOL)isLandscape {
    if (isLandscape) {
        // Landscape: Slightly smaller fonts to fit more content
        self.chatTextView.font = [UIFont systemFontOfSize:15];
        self.inputTextField.font = [UIFont systemFontOfSize:15];
    } else {
        // Portrait: Standard fonts
        self.chatTextView.font = [UIFont systemFontOfSize:16];
        self.inputTextField.font = [UIFont systemFontOfSize:16];
    }
}

// NEW - Support all orientations
- (BOOL)shouldAutorotate {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationPortrait;
}

// Add this new method for handling the clear button tap:
- (void)clearButtonTapped {
    // Show confirmation alert to prevent accidental clearing
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Clear Chat" 
                                                                   message:@"This will clear all chat history and start a fresh conversation. This action cannot be undone." 
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    // Cancel action
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" 
                                                           style:UIAlertActionStyleCancel 
                                                         handler:nil];
    
    // Clear action (destructive style)
    UIAlertAction *clearAction = [UIAlertAction actionWithTitle:@"Clear Chat" 
                                                          style:UIAlertActionStyleDestructive 
                                                        handler:^(UIAlertAction * _Nonnull action) {
        [self clearChatHistory];
    }];
    
    [alert addAction:cancelAction];
    [alert addAction:clearAction];
    
    [self presentViewController:alert animated:YES completion:nil];
}

// Add this new method to actually clear the chat:
- (void)clearChatHistory {
    NSLog(@"🧹 Clearing chat history and context");
    
    // Stop any ongoing generation
    if (self.isAutoGenerating) {
        [self stopGeneration];
    }
    
    // Reset all generation state
    self.fullResponse = @"";
    self.totalTokensGenerated = 0;
    self.consecutiveIncompleteTokens = 0;
    self.shouldStopGeneration = NO;
    self.lastUserInput = nil;
    
    // Disable continue button
    self.navigationItem.leftBarButtonItem.enabled = NO;
    
    // Clear the chat display
    self.chatTextView.text = @"";
    self.chatTextView.attributedText = [[NSAttributedString alloc] initWithString:@""];
    
    // Add fresh welcome message
    [self appendToChatLog:@"✨ Chat cleared! Ready for a new conversation." fromUser:NO];
    
    // Reset response length if it was reduced due to memory pressure
    SettingsViewController *settings = [SettingsViewController sharedSettings];
    self.maxResponseTokens = MAX(settings.maxTokens, 100);
    
    // Clear input field if it has text
    self.inputTextField.text = @"";
    
    // Log memory status after clearing
    [[MemoryProfiler shared] logCurrentMemoryUsage:@"After chat clear"];
    
    NSLog(@"✅ Chat history cleared successfully");
}

- (void)setupMemoryMonitoring {
    // Monitor memory pressure
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleMemoryPressure:)
                                                 name:@"MemoryPressureWarning"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleCriticalMemoryPressure:)
                                                 name:@"CriticalMemoryPressure"
                                               object:nil];
}

- (void)handleMemoryPressure:(NSNotification *)notification {
    NSLog(@"⚠️ Memory pressure - will reduce next response length");
    // Only reduce for NEXT response, don't interrupt current generation
    if (!self.isAutoGenerating) {
        self.maxResponseTokens = MAX(50, self.maxResponseTokens - 30);
    }
}

- (void)handleCriticalMemoryPressure:(NSNotification *)notification {
    NSLog(@"🚨 Critical memory pressure - stopping current generation");
    // Only stop in truly critical situations
    if (self.isAutoGenerating && self.totalTokensGenerated > 100) {
        [self stopGeneration];
    }
}

- (void)setupUI {
    // Skip the scroll view entirely and use just a text view
    self.chatTextView = [[UITextView alloc] init];
    self.chatTextView.translatesAutoresizingMaskIntoConstraints = NO;
    self.chatTextView.editable = NO;
    self.chatTextView.scrollEnabled = YES;
    self.chatTextView.backgroundColor = [UIColor secondarySystemBackgroundColor];
    self.chatTextView.layer.cornerRadius = 8;
    self.chatTextView.font = [UIFont systemFontOfSize:16];
    self.chatTextView.textContainerInset = UIEdgeInsetsMake(12, 12, 12, 12);
    
    // Remove debug border
    // self.chatTextView.layer.borderWidth = 3.0;
    // self.chatTextView.layer.borderColor = [UIColor redColor].CGColor;
    
    [self.view addSubview:self.chatTextView];
    
    // Create input container view
    self.inputContainerView = [[UIView alloc] init];
    self.inputContainerView.translatesAutoresizingMaskIntoConstraints = NO;
    self.inputContainerView.backgroundColor = [UIColor systemBackgroundColor];
    // Remove debug border
    // self.inputContainerView.layer.borderWidth = 2.0;
    // self.inputContainerView.layer.borderColor = [UIColor blueColor].CGColor;
    [self.view addSubview:self.inputContainerView];
    
    // Create input text field
    self.inputTextField = [[UITextField alloc] init];
    self.inputTextField.translatesAutoresizingMaskIntoConstraints = NO;
    self.inputTextField.borderStyle = UITextBorderStyleRoundedRect;
    self.inputTextField.placeholder = @"Type your message...";
    self.inputTextField.delegate = self;
    self.inputTextField.returnKeyType = UIReturnKeySend;
    [self.inputContainerView addSubview:self.inputTextField];
    
    // Create send button
    self.sendButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.sendButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.sendButton setTitle:@"Send" forState:UIControlStateNormal];
    [self.sendButton setTitleColor:[UIColor systemBlueColor] forState:UIControlStateNormal];
    self.sendButton.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    [self.sendButton addTarget:self action:@selector(sendMessage) forControlEvents:UIControlEventTouchUpInside];
    [self.inputContainerView addSubview:self.sendButton];
    
    // Setup constraints
    [self setupConstraints];
}

// ENSURE proper constraint setup
- (void)setupConstraints {
    UILayoutGuide *safeArea = self.view.safeAreaLayoutGuide;
    
    // Input container constraints
    self.inputBottomConstraint = [self.inputContainerView.bottomAnchor constraintEqualToAnchor:safeArea.bottomAnchor];
    self.inputHeightConstraint = [self.inputContainerView.heightAnchor constraintEqualToConstant:60];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.inputContainerView.leadingAnchor constraintEqualToAnchor:safeArea.leadingAnchor],
        [self.inputContainerView.trailingAnchor constraintEqualToAnchor:safeArea.trailingAnchor],
        self.inputBottomConstraint,
        self.inputHeightConstraint
    ]];
    
    // Send button constraints
    [NSLayoutConstraint activateConstraints:@[
        [self.sendButton.trailingAnchor constraintEqualToAnchor:self.inputContainerView.trailingAnchor constant:-12],
        [self.sendButton.centerYAnchor constraintEqualToAnchor:self.inputContainerView.centerYAnchor],
        [self.sendButton.widthAnchor constraintEqualToConstant:60],
        [self.sendButton.heightAnchor constraintEqualToConstant:40]
    ]];
    
    // Text field constraints
    [NSLayoutConstraint activateConstraints:@[
        [self.inputTextField.leadingAnchor constraintEqualToAnchor:self.inputContainerView.leadingAnchor constant:12],
        [self.inputTextField.trailingAnchor constraintEqualToAnchor:self.sendButton.leadingAnchor constant:-8],
        [self.inputTextField.centerYAnchor constraintEqualToAnchor:self.inputContainerView.centerYAnchor],
        [self.inputTextField.heightAnchor constraintEqualToConstant:40]
    ]];
    
    // CRITICAL: Store constraint references for orientation changes
    self.chatTopConstraint = [self.chatTextView.topAnchor constraintEqualToAnchor:safeArea.topAnchor constant:8];
    self.chatLeadingConstraint = [self.chatTextView.leadingAnchor constraintEqualToAnchor:safeArea.leadingAnchor constant:8];
    self.chatTrailingConstraint = [self.chatTextView.trailingAnchor constraintEqualToAnchor:safeArea.trailingAnchor constant:-8];
    
    [NSLayoutConstraint activateConstraints:@[
        self.chatTopConstraint,
        self.chatLeadingConstraint,
        self.chatTrailingConstraint,
        [self.chatTextView.bottomAnchor constraintEqualToAnchor:self.inputContainerView.topAnchor constant:-8]
    ]];
    
    NSLog(@"🔧 Constraints setup with references stored");
    
    // Set initial layout
    [self updateLayoutForSize:self.view.bounds.size];
}

- (void)setupKeyboardNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

// UPDATED - Enhanced keyboard handling for different orientations
- (void)keyboardWillShow:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    NSValue *keyboardFrame = userInfo[UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardRect = [keyboardFrame CGRectValue];
    
    // Convert keyboard frame to view coordinates
    CGRect keyboardViewFrame = [self.view convertRect:keyboardRect fromView:nil];
    CGFloat keyboardHeight = keyboardViewFrame.size.height;
    
    NSTimeInterval duration = [userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    NSInteger curveValue = [userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue];
    UIViewAnimationCurve curve = (UIViewAnimationCurve)curveValue;    
    NSLog(@"📱 Keyboard showing: height=%.1f", keyboardHeight);
    
    // Adjust keyboard offset based on orientation
    BOOL isLandscape = self.view.bounds.size.width > self.view.bounds.size.height;
    CGFloat additionalOffset = isLandscape ? 0 : 0; // Could add extra space in landscape if needed
    
    // Update the bottom constraint to move input above keyboard
    self.inputBottomConstraint.constant = -(keyboardHeight + additionalOffset);
    
    [UIView animateWithDuration:duration
                          delay:0
                        options:(UIViewAnimationOptions)(curve << 16)
                     animations:^{
        [self.view layoutIfNeeded];
    } completion:^(BOOL finished) {
        // Ensure chat remains scrolled to bottom when keyboard appears
        [self scrollToBottom];
    }];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    NSTimeInterval duration = [userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    NSInteger curveValue = [userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue];
    UIViewAnimationCurve curve = (UIViewAnimationCurve)curveValue;
    
    NSLog(@"📱 Keyboard hiding");
    
    // Reset the bottom constraint to safe area
    self.inputBottomConstraint.constant = 0;
    
    [UIView animateWithDuration:duration
                          delay:0
                        options:(UIViewAnimationOptions)(curve << 16)
                     animations:^{
        [self.view layoutIfNeeded];
    } completion:nil];
}

// UPDATED - Enhanced appendToChatLog with orientation-aware formatting
- (void)appendToChatLog:(NSString *)message fromUser:(BOOL)isUser {
    NSString *prefix = isUser ? @"👤 You: " : @"🤖 PHI3: ";
    NSString *fullMessage = [NSString stringWithFormat:@"%@%@\n\n", prefix, message];
    
    // Create attributed string for better formatting
    NSMutableAttributedString *attributedMessage = [[NSMutableAttributedString alloc] initWithString:fullMessage];
    
    // Adjust line spacing based on orientation for better readability
    BOOL isLandscape = self.view.bounds.size.width > self.view.bounds.size.height;
    CGFloat lineSpacing = isLandscape ? 2.0 : 4.0;
    
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineSpacing = lineSpacing;
    
    [attributedMessage addAttribute:NSParagraphStyleAttributeName
                              value:paragraphStyle
                              range:NSMakeRange(0, fullMessage.length)];
    
    // Style the prefix
    NSRange prefixRange = [fullMessage rangeOfString:prefix];
    [attributedMessage addAttribute:NSFontAttributeName
                              value:[UIFont boldSystemFontOfSize:isLandscape ? 15 : 16]
                              range:prefixRange];
    
    // Color coding
    UIColor *color = isUser ? [UIColor systemBlueColor] : [UIColor systemGreenColor];
    [attributedMessage addAttribute:NSForegroundColorAttributeName
                              value:color
                              range:prefixRange];
    
    // Append to existing text
    NSMutableAttributedString *existingText = [[NSMutableAttributedString alloc] initWithAttributedString:self.chatTextView.attributedText];
    [existingText appendAttributedString:attributedMessage];
    
    self.chatTextView.attributedText = existingText;
    
    // Scroll to bottom
    [self scrollToBottom];
}

// UPDATED - Enhanced scrollToBottom that works better in landscape
- (void)scrollToBottom {
    if (self.chatTextView.text.length > 0) {
        // Use content size instead of text length for more reliable scrolling
        CGFloat contentHeight = self.chatTextView.contentSize.height;
        CGFloat textViewHeight = self.chatTextView.bounds.size.height;
        
        if (contentHeight > textViewHeight) {
            CGPoint bottomOffset = CGPointMake(0, contentHeight - textViewHeight + self.chatTextView.textContainerInset.top + self.chatTextView.textContainerInset.bottom);
            [self.chatTextView setContentOffset:bottomOffset animated:YES];
        }
    }
}

// ... [REST OF YOUR EXISTING METHODS REMAIN UNCHANGED] ...
// sendMessage, processNewMessage, startStreamingGeneration, handleNewToken, 
// updateCurrentResponse, shouldStopGenerationWithToken, isNaturalStoppingPoint,
// isGeneratingPoorContent, scheduleAutoScroll, stopGeneration, finishGeneration,
// shouldOfferContinuation, continueGeneration, forceStopGeneration, removeLastMessage,
// settingsButtonTapped, settingsDidChange, textFieldShouldReturn

- (void)sendMessage {
    NSString *message = [self.inputTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if (message.length == 0) {
        return;
    }
    
    // Disable continue button when starting new conversation
    self.navigationItem.leftBarButtonItem.enabled = NO;
    
    // Stop any current generation immediately
    if (self.isAutoGenerating) {
        NSLog(@"🛑 Stopping previous generation due to new user input");
        [self stopGeneration];
        
        // Wait a moment for cleanup before starting new generation
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self processNewMessage:message];
        });
        return;
    }
    
    [self processNewMessage:message];
}

- (void)processNewMessage:(NSString *)message {
    // Reset state for new conversation
    self.fullResponse = @"";
    self.totalTokensGenerated = 0;
    self.consecutiveIncompleteTokens = 0;
    self.shouldStopGeneration = NO;
    
    // Add user message to chat
    [self appendToChatLog:message fromUser:YES];
    self.lastUserInput = message;
    
    // Clear input field
    self.inputTextField.text = @"";
    
    // Start streaming generation
    [self startStreamingGeneration:message];
}

- (void)startStreamingGeneration:(NSString *)userInput {
    // Only stop if actually generating
    if (self.isAutoGenerating) {
        [self forceStopGeneration];
        // Wait for cleanup
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self startStreamingGeneration:userInput];
        });
        return;
    }
    
    // Reset state for new generation
    self.shouldStopGeneration = NO;
    self.isAutoGenerating = YES;
    self.fullResponse = @""; // Reset response
    self.totalTokensGenerated = 0;
    
    // Change left button to Stop while generating
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]
                                            initWithTitle:@"Stop"
                                            style:UIBarButtonItemStylePlain
                                            target:self
                                            action:@selector(stopGeneration)];
    self.navigationItem.leftBarButtonItem.enabled = YES;
    
    // Show initial thinking state with proper prefix
    [self appendToChatLog:@"Thinking..." fromUser:NO];
    
    NSLog(@"📺 Initial chat content: %@", self.chatTextView.text);
    
    dispatch_async(self.inferenceQueue, ^{
        __weak ChatViewController *weakSelf = self;
        
        NSLog(@"🚀 Starting C++ generation for: %@", userInput);
        
        // Use streaming generation with token callback
        std::string response = generatePhi3ResponseStreaming(
            [userInput UTF8String], 
            [self.modelPath UTF8String],
            self.maxResponseTokens,
            512, // Hard limit for total context
            ^(const char* token, bool isComplete) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    ChatViewController *strongSelf = weakSelf;
                    if (strongSelf && !strongSelf.shouldStopGeneration) {
                        [strongSelf handleNewToken:[NSString stringWithUTF8String:token] 
                                        isComplete:isComplete];
                    }
                });
            }
        );
        
        NSLog(@"🏁 C++ generation completed");
        
        dispatch_async(dispatch_get_main_queue(), ^{
            ChatViewController *strongSelf = weakSelf;
            if (strongSelf) {
                [strongSelf finishGeneration];
            }
        });
    });
}

- (void)handleNewToken:(NSString *)token isComplete:(BOOL)isComplete {
    // Check if generation was stopped (e.g., by new user input)
    if (self.shouldStopGeneration) {
        NSLog(@"🛑 Token ignored - generation was stopped");
        return;
    }
    
    // Validate token before processing
    if (!token) {
        NSLog(@"⚠️ Received nil token, isComplete: %d", isComplete);
        if (isComplete) {
            [self finishGeneration];
        }
        return;
    }
    
    if (token.length == 0) {
        NSLog(@"⚠️ Received empty token, isComplete: %d", isComplete);
        if (isComplete) {
            [self finishGeneration];
        }
        return;
    }
    
    NSLog(@"📝 Received token: '%@' (length: %lu, complete: %d)", token, (unsigned long)token.length, isComplete);
    
    // Append token to response
    self.fullResponse = [self.fullResponse stringByAppendingString:token];
    self.totalTokensGenerated++;
    
    // Update the chat display in real-time
    [self updateCurrentResponse];
    
    // Check stopping conditions
    if ([self shouldStopGenerationWithToken:token] || isComplete) {
        NSLog(@"🏁 Finishing generation due to stopping condition or completion");
        [self finishGeneration];
        return;
    }
    
    // Auto-scroll for smooth reading
    [self scheduleAutoScroll];
}

- (void)updateCurrentResponse {
    // Replace the last response with updated content
    NSString *currentText = self.chatTextView.text;
    NSRange lastBotRange = [currentText rangeOfString:@"🤖 PHI3: " options:NSBackwardsSearch];
    
    if (lastBotRange.location != NSNotFound) {
        NSLog(@"📺 Updating UI with response length: %lu", (unsigned long)self.fullResponse.length);
        
        // Find the end of the last bot message
        NSString *afterBot = [currentText substringFromIndex:lastBotRange.location];
        NSRange nextUserRange = [afterBot rangeOfString:@"👤 You: "];
        
        NSString *beforeBot = [currentText substringToIndex:lastBotRange.location];
        NSString *updatedResponse = [NSString stringWithFormat:@"🤖 PHI3: %@", self.fullResponse];
        
        if (nextUserRange.location != NSNotFound) {
            // There's a user message after this bot message
            NSString *afterResponse = [currentText substringFromIndex:lastBotRange.location + nextUserRange.location];
            self.chatTextView.text = [NSString stringWithFormat:@"%@%@%@", beforeBot, updatedResponse, afterResponse];
        } else {
            // This is the last message
            self.chatTextView.text = [NSString stringWithFormat:@"%@%@\n\n", beforeBot, updatedResponse];
        }
        
        NSLog(@"📺 UI updated successfully");
    } else {
        NSLog(@"⚠️ Could not find bot message to update in chat");
        // Fallback: just append the response
        [self appendToChatLog:self.fullResponse fromUser:NO];
    }
}

- (BOOL)shouldStopGenerationWithToken:(NSString *)token {
    // Primary stopping condition: Token limit
    if (self.totalTokensGenerated >= self.maxResponseTokens) {
        NSLog(@"🛑 Stopping generation - reached token limit (%ld tokens)", (long)self.totalTokensGenerated);
        return YES;
    }
    
    // Only check for natural stopping points after generating a reasonable amount
    if (self.totalTokensGenerated >= 20 && [self isNaturalStoppingPoint:token]) {
        NSLog(@"🛑 Stopping generation - reached natural stopping point at %ld tokens", (long)self.totalTokensGenerated);
        return YES;
    }
    
    // Quality control - but only after minimum content
    if (self.totalTokensGenerated >= 30 && [self isGeneratingPoorContent:token]) {
        NSLog(@"🛑 Stopping generation - quality control at %ld tokens", (long)self.totalTokensGenerated);
        return YES;
    }
    
    // Hard safety limit to prevent runaway generation
    if (self.totalTokensGenerated >= 500) {
        NSLog(@"🛑 Stopping generation - hard safety limit reached");
        return YES;
    }
    
    return NO;
}

- (BOOL)isNaturalStoppingPoint:(NSString *)token {
    // Check for sentence endings with sufficient content
    if ([token containsString:@"."] || [token containsString:@"!"] || [token containsString:@"?"]) {
        // Only consider natural stopping if we have substantial content
        if (self.totalTokensGenerated >= 40) {
            return YES;
        }
    }
    
    // Check for paragraph breaks (double newlines) with good content
    if ([token containsString:@"\n\n"] && self.totalTokensGenerated >= 50) {
        return YES;
    }
    
    // Check for conversation enders - but only with sufficient content
    if (self.totalTokensGenerated >= 30) {
        NSArray *endPhrases = @[@"Hope this helps", @"Let me know", @"Feel free", 
                               @"Any questions", @"That should", @"In summary"];
        for (NSString *phrase in endPhrases) {
            if ([self.fullResponse.lowercaseString containsString:phrase.lowercaseString]) {
                return YES;
            }
        }
    }
    
    // Check for complete code blocks
    if ([token containsString:@"```"] && [self.fullResponse componentsSeparatedByString:@"```"].count >= 3) {
        return YES;
    }
    
    return NO;
}

- (BOOL)isGeneratingPoorContent:(NSString *)token {
    // Check for repetition
    if (token.length > 0) {
        NSString *lastChars = self.fullResponse.length >= 20 ? 
            [self.fullResponse substringFromIndex:self.fullResponse.length - 20] : self.fullResponse;
        
        NSInteger repetitionCount = 0;
        for (NSInteger i = 0; i < lastChars.length - 1; i++) {
            if ([lastChars characterAtIndex:i] == [lastChars characterAtIndex:i + 1]) {
                repetitionCount++;
            }
        }
        
        if (repetitionCount > 10) { // Too much repetition
            return YES;
        }
    }
    
    // Check for incomplete tokens
    if (token.length == 0 || [token isEqualToString:@" "]) {
        self.consecutiveIncompleteTokens++;
        if (self.consecutiveIncompleteTokens > 5) {
            return YES;
        }
    } else {
        self.consecutiveIncompleteTokens = 0;
    }
    
    return NO;
}

- (void)scheduleAutoScroll {
    // Cancel previous timer
    [self.autoScrollTimer invalidate];
    
    // Schedule scroll with slight delay for smooth reading
    self.autoScrollTimer = [NSTimer scheduledTimerWithTimeInterval:0.1
                                                           repeats:NO
                                                             block:^(NSTimer *timer) {
        [self scrollToBottom];
    }];
}

- (void)stopGeneration {
    NSLog(@"🛑 Stopping generation");
    self.shouldStopGeneration = YES;
    
    // Signal C++ to stop generation
    cancelPhi3Generation();
    
    // Cancel any pending auto-scroll
    [self.autoScrollTimer invalidate];
    
    // Update UI immediately
    self.isAutoGenerating = NO;
    
    // Change back to Continue button
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]
                                            initWithTitle:@"Continue"
                                            style:UIBarButtonItemStylePlain
                                            target:self
                                            action:@selector(continueGeneration)];
    self.navigationItem.leftBarButtonItem.enabled = NO;
    
    // Add completion marker to indicate response was interrupted if it was short
    if (self.totalTokensGenerated < 10 && self.fullResponse.length > 0) {
        self.fullResponse = [self.fullResponse stringByAppendingString:@" [interrupted]"];
        [self updateCurrentResponse];
    }
    
    // Log final stats
    NSLog(@"✅ Generation stopped: %ld tokens generated", (long)self.totalTokensGenerated);
}

- (void)finishGeneration {
    // Only finish if we're actually generating and haven't been stopped
    if (!self.isAutoGenerating) {
        return;
    }
    
    self.isAutoGenerating = NO;
    [self.autoScrollTimer invalidate];
    
    // Change back to Continue button and enable it if appropriate
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]
                                            initWithTitle:@"Continue"
                                            style:UIBarButtonItemStylePlain
                                            target:self
                                            action:@selector(continueGeneration)];
    
    // Enable continue button if response seems like it could be expanded
    self.navigationItem.leftBarButtonItem.enabled = [self shouldOfferContinuation];
    
    if (self.navigationItem.leftBarButtonItem.enabled) {
        NSLog(@"💡 Continue button enabled - user can request more details");
    }
    
    // Log final stats
    NSLog(@"✅ Generation complete: %ld tokens, %.1f KB", 
          (long)self.totalTokensGenerated, 
          self.fullResponse.length * sizeof(unichar) / 1024.0);
    
    // Log memory status
    [[MemoryProfiler shared] logCurrentMemoryUsage:@"After generation"];
    
    // Restore response length if it was reduced due to memory pressure
    SettingsViewController *settings = [SettingsViewController sharedSettings];
    self.maxResponseTokens = MAX(settings.maxTokens, 100);
}

- (BOOL)shouldOfferContinuation {
    // Only show continue for responses with some content
    if (self.totalTokensGenerated < 10) {
        return NO;
    }
    
    // Always allow continuation if we have any substantial response
    if (self.fullResponse.length > 20) {
        return YES;
    }
    
    return NO;
}

- (void)continueGeneration {
    // Prevent multiple simultaneous continuations
    if (!self.lastUserInput || self.fullResponse.length == 0 || self.isAutoGenerating) {
        NSLog(@"⚠️ Continue ignored - already generating or no content");
        return;
    }
    
    NSLog(@"➡️ User requested continuation");
    
    // Reset generation state for continuation
    self.shouldStopGeneration = NO;
    self.isAutoGenerating = YES;
    
    // Change to Stop button while generating continuation
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]
                                            initWithTitle:@"Stop"
                                            style:UIBarButtonItemStylePlain
                                            target:self
                                            action:@selector(stopGeneration)];
    self.navigationItem.leftBarButtonItem.enabled = YES;
    
    // Show continuation indicator
    [self appendToChatLog:@"🤖 Continuing..." fromUser:NO];
    
    dispatch_async(self.inferenceQueue, ^{
        NSLog(@"🚀 Starting C++ continuation");
        
        // Use continuation function
        std::string continuation = generatePhi3ResponseContinuation(
            [self.lastUserInput UTF8String],
            [self.fullResponse UTF8String],
            [self.modelPath UTF8String],
            60 // Reduced token count to prevent memory issues
        );
        
        NSLog(@"🏁 C++ continuation completed");
        
        dispatch_async(dispatch_get_main_queue(), ^{
            // Remove "Continuing..." message
            [self removeLastMessage];
            
            if (!self.shouldStopGeneration && continuation.length() > 0) {
                NSString *continuationStr = [NSString stringWithUTF8String:continuation.c_str()];
                
                // Append to existing response
                self.fullResponse = [self.fullResponse stringByAppendingFormat:@" %@", continuationStr];
                self.totalTokensGenerated += 60; // Approximate
                
                // Update display
                [self updateCurrentResponse];
                [self scrollToBottom];
                
                NSLog(@"✅ Continuation added: %lu characters", (unsigned long)continuationStr.length);
            } else if (!self.shouldStopGeneration) {
                [self appendToChatLog:@"I don't have anything more to add on this topic." fromUser:NO];
            }
            
            // Finish and check if we can continue again
            [self finishGeneration];
        });
    });
}

- (void)forceStopGeneration {
    NSLog(@"🚨 Force stopping any existing generation");
    self.shouldStopGeneration = YES;
    cancelPhi3Generation();
    [self.autoScrollTimer invalidate];
    
    // Wait briefly for any background operations to complete
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.05 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // Reset state
        self.isAutoGenerating = NO;
    });
}

- (void)removeLastMessage {
    NSString *text = self.chatTextView.text;
    NSArray *lines = [text componentsSeparatedByString:@"\n"];
    
    // Remove last few lines (message + empty line)
    NSMutableArray *mutableLines = [lines mutableCopy];
    while (mutableLines.count > 0 && [[mutableLines.lastObject stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] == 0) {
        [mutableLines removeLastObject];
    }
    if (mutableLines.count > 0) {
        [mutableLines removeLastObject]; // Remove the actual message
    }
    
    self.chatTextView.text = [mutableLines componentsJoinedByString:@"\n"];
}

- (void)settingsButtonTapped {
    SettingsViewController *settingsVC = [[SettingsViewController alloc] init];
    settingsVC.delegate = self;
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:settingsVC];
    [self presentViewController:navController animated:YES completion:nil];
}

#pragma mark - SettingsDelegate
- (void)settingsDidChange {
    SettingsViewController *settings = [SettingsViewController sharedSettings];
    self.maxResponseTokens = settings.maxTokens;
    [self appendToChatLog:@"⚙️ Settings updated - new response length applied!" fromUser:NO];
}

#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self sendMessage];
    return YES;
}

// ENHANCED dealloc to properly clean up
- (void)dealloc {
    NSLog(@"🔧 ChatViewController dealloc - cleaning up");
    
    // Stop device orientation notifications
    if ([UIDevice currentDevice].isGeneratingDeviceOrientationNotifications) {
        [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.autoScrollTimer invalidate];
    [[MemoryProfiler shared] stopProfiling];
}

@end

// Enhanced C++ streaming function with proper cancellation
std::string generatePhi3ResponseStreaming(const char* user_input, const char* model_path, 
                                        int target_tokens, int max_total_tokens,
                                        void(^tokenCallback)(const char* token, bool isComplete)) {
    
    // Reset cancellation flag for new generation
    g_should_cancel_generation = false;
    
    try {
        // Create model
        OgaModel* model = nullptr;
        if (OgaCreateModel(model_path, &model) != nullptr) {
            return "❌ Failed to load model";
        }
        
        // Create tokenizer
        OgaTokenizer* tokenizer = nullptr;
        if (OgaCreateTokenizer(model, &tokenizer) != nullptr) {
            OgaDestroyModel(model);
            return "❌ Failed to create tokenizer";
        }
        
        // Create tokenizer stream
        OgaTokenizerStream* tokenizer_stream = nullptr;
        if (OgaCreateTokenizerStream(tokenizer, &tokenizer_stream) != nullptr) {
            OgaDestroyTokenizer(tokenizer);
            OgaDestroyModel(model);
            return "❌ Failed to create tokenizer stream";
        }
        
        // Format with chat template
        std::string chat_template = "<|user|>\n";
        chat_template += user_input;
        chat_template += " <|end|>\n<|assistant|>";
        
        // Encode
        OgaSequences* input_sequences = nullptr;
        if (OgaCreateSequences(&input_sequences) != nullptr) {
            OgaDestroyTokenizerStream(tokenizer_stream);
            OgaDestroyTokenizer(tokenizer);
            OgaDestroyModel(model);
            return "❌ Failed to create sequences";
        }
        
        if (OgaTokenizerEncode(tokenizer, chat_template.c_str(), input_sequences) != nullptr) {
            OgaDestroySequences(input_sequences);
            OgaDestroyTokenizerStream(tokenizer_stream);
            OgaDestroyTokenizer(tokenizer);
            OgaDestroyModel(model);
            return "❌ Failed to encode prompt";
        }
        
        // Create generator with custom parameters
        OgaGeneratorParams* params = nullptr;
        if (OgaCreateGeneratorParams(model, &params) != nullptr) {
            OgaDestroySequences(input_sequences);
            OgaDestroyTokenizerStream(tokenizer_stream);
            OgaDestroyTokenizer(tokenizer);
            OgaDestroyModel(model);
            return "❌ Failed to create generator params";
        }
        
        // Optimized settings for streaming
        OgaGeneratorParamsSetSearchNumber(params, "max_length", (double)max_total_tokens);
        OgaGeneratorParamsSetSearchNumber(params, "temperature", 0.7);
        OgaGeneratorParamsSetSearchNumber(params, "top_p", 0.9);
        
        OgaGenerator* generator = nullptr;
        if (OgaCreateGenerator(model, params, &generator) != nullptr) {
            OgaDestroyGeneratorParams(params);
            OgaDestroySequences(input_sequences);
            OgaDestroyTokenizerStream(tokenizer_stream);
            OgaDestroyTokenizer(tokenizer);
            OgaDestroyModel(model);
            return "❌ Failed to create generator";
        }
        
        if (OgaGenerator_AppendTokenSequences(generator, input_sequences) != nullptr) {
            OgaDestroyGenerator(generator);
            OgaDestroyGeneratorParams(params);
            OgaDestroySequences(input_sequences);
            OgaDestroyTokenizerStream(tokenizer_stream);
            OgaDestroyTokenizer(tokenizer);
            OgaDestroyModel(model);
            return "❌ Failed to append tokens";
        }
        
        // Streaming generation loop with cancellation checks
        std::string full_response;
        int token_count = 0;
        
        while (!OgaGenerator_IsDone(generator) && token_count < target_tokens && !g_should_cancel_generation) {
            if (OgaGenerator_GenerateNextToken(generator) != nullptr || g_should_cancel_generation) {
                break;
            }
            
            const int32_t* tokens = nullptr;
            size_t token_count_batch = 0;
            
            if (OgaGenerator_GetNextTokens(generator, &tokens, &token_count_batch) != nullptr || g_should_cancel_generation) {
                break;
            }
            
            if (token_count_batch > 0 && !g_should_cancel_generation) {
                int32_t new_token = tokens[token_count_batch - 1];
                
                const char* token_text = nullptr;
                if (OgaTokenizerStreamDecode(tokenizer_stream, new_token, &token_text) == nullptr && !g_should_cancel_generation) {
                    std::string token_str(token_text);
                    
                    if (token_str.find("<|end|>") != std::string::npos) {
                        break;
                    }
                    
                    full_response += token_str;
                    
                    // Stream callback for real-time updates
                    if (tokenCallback && !g_should_cancel_generation) {
                        tokenCallback(token_text, false);
                    }
                }
            }
            
            token_count++;
            
            // Reduced delay for smooth streaming
            if (!g_should_cancel_generation) {
                usleep(5000); // 5ms delay
            }
        }
        
        // Final callback only if not cancelled
        if (tokenCallback && !g_should_cancel_generation) {
            tokenCallback("", true);
        }
        
        // Cleanup
        OgaDestroyGenerator(generator);
        OgaDestroyGeneratorParams(params);
        OgaDestroySequences(input_sequences);
        OgaDestroyTokenizerStream(tokenizer_stream);
        OgaDestroyTokenizer(tokenizer);
        OgaDestroyModel(model);
        
        return g_should_cancel_generation ? "Generation cancelled" : full_response;
        
    } catch (...) {
        return "❌ An error occurred during streaming generation";
    }
}

// C++ function for continuation (builds on previous response)
std::string generatePhi3ResponseContinuation(const char* user_input, const char* previous_response, const char* model_path, int max_tokens) {
    try {
        // Create model
        OgaModel* model = nullptr;
        if (OgaCreateModel(model_path, &model) != nullptr) {
            return "❌ Failed to load model";
        }
        
        // Create tokenizer
        OgaTokenizer* tokenizer = nullptr;
        if (OgaCreateTokenizer(model, &tokenizer) != nullptr) {
            OgaDestroyModel(model);
            return "❌ Failed to create tokenizer";
        }
        
        // Create tokenizer stream
        OgaTokenizerStream* tokenizer_stream = nullptr;
        if (OgaCreateTokenizerStream(tokenizer, &tokenizer_stream) != nullptr) {
            OgaDestroyTokenizer(tokenizer);
            OgaDestroyModel(model);
            return "❌ Failed to create tokenizer stream";
        }
        
        // Build continuation prompt
        std::string chat_template = "<|user|>\n";
        chat_template += user_input;
        chat_template += " <|end|>\n<|assistant|>";
        chat_template += previous_response;
        // Don't add <|end|> - let it continue naturally
        
        // Encode
        OgaSequences* input_sequences = nullptr;
        if (OgaCreateSequences(&input_sequences) != nullptr) {
            OgaDestroyTokenizerStream(tokenizer_stream);
            OgaDestroyTokenizer(tokenizer);
            OgaDestroyModel(model);
            return "❌ Failed to create sequences";
        }
        
        if (OgaTokenizerEncode(tokenizer, chat_template.c_str(), input_sequences) != nullptr) {
            OgaDestroySequences(input_sequences);
            OgaDestroyTokenizerStream(tokenizer_stream);
            OgaDestroyTokenizer(tokenizer);
            OgaDestroyModel(model);
            return "❌ Failed to encode prompt";
        }
        
        // Create generator
        OgaGeneratorParams* params = nullptr;
        if (OgaCreateGeneratorParams(model, &params) != nullptr) {
            OgaDestroySequences(input_sequences);
            OgaDestroyTokenizerStream(tokenizer_stream);
            OgaDestroyTokenizer(tokenizer);
            OgaDestroyModel(model);
            return "❌ Failed to create generator params";
        }
        
        OgaGeneratorParamsSetSearchNumber(params, "max_length", 512.0);
        OgaGeneratorParamsSetSearchNumber(params, "temperature", 0.7);
        OgaGeneratorParamsSetSearchNumber(params, "top_p", 0.9);
        
        OgaGenerator* generator = nullptr;
        if (OgaCreateGenerator(model, params, &generator) != nullptr) {
            OgaDestroyGeneratorParams(params);
            OgaDestroySequences(input_sequences);
            OgaDestroyTokenizerStream(tokenizer_stream);
            OgaDestroyTokenizer(tokenizer);
            OgaDestroyModel(model);
            return "❌ Failed to create generator";
        }
        
        if (OgaGenerator_AppendTokenSequences(generator, input_sequences) != nullptr) {
            OgaDestroyGenerator(generator);
            OgaDestroyGeneratorParams(params);
            OgaDestroySequences(input_sequences);
            OgaDestroyTokenizerStream(tokenizer_stream);
            OgaDestroyTokenizer(tokenizer);
            OgaDestroyModel(model);
            return "❌ Failed to append tokens";
        }
        
        // Generate continuation
        std::string response;
        int token_count = 0;
        
        while (!OgaGenerator_IsDone(generator) && token_count < max_tokens) {
            if (OgaGenerator_GenerateNextToken(generator) != nullptr) {
                break;
            }
            
            const int32_t* tokens = nullptr;
            size_t token_count_batch = 0;
            
            if (OgaGenerator_GetNextTokens(generator, &tokens, &token_count_batch) != nullptr) {
                break;
            }
            
            if (token_count_batch > 0) {
                int32_t new_token = tokens[token_count_batch - 1];
                
                const char* token_text = nullptr;
                if (OgaTokenizerStreamDecode(tokenizer_stream, new_token, &token_text) == nullptr) {
                    response += token_text;
                    
                    if (std::string(token_text).find("<|end|>") != std::string::npos) {
                        break;
                    }
                }
            }
            
            token_count++;
        }
        
        // Cleanup
        OgaDestroyGenerator(generator);
        OgaDestroyGeneratorParams(params);
        OgaDestroySequences(input_sequences);
        OgaDestroyTokenizerStream(tokenizer_stream);
        OgaDestroyTokenizer(tokenizer);
        OgaDestroyModel(model);
        
        // Clean up response
        size_t end_pos = response.find("<|end|>");
        if (end_pos != std::string::npos) {
            response = response.substr(0, end_pos);
        }
        
        return response.empty() ? "That's all I have to add for now." : response;
        
    } catch (...) {
        return "❌ An error occurred while generating continuation";
    }
}
