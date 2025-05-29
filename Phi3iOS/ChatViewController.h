#import <UIKit/UIKit.h>

@interface ChatViewController : UIViewController <UITextFieldDelegate>

@property (strong, nonatomic) UIScrollView *scrollView;
@property (strong, nonatomic) UITextView *chatTextView;
@property (strong, nonatomic) UITextField *inputTextField;
@property (strong, nonatomic) UIButton *sendButton;
@property (strong, nonatomic) UIView *inputContainerView;
@property (strong, nonatomic) UIButton *continueButton;
@property (strong, nonatomic) NSString *currentPartialResponse;
@property (strong, nonatomic) NSString *lastUserInput;
@property (nonatomic) BOOL isGenerating;
@property (strong, nonatomic) NSString *preGeneratedContinuation;
@property (nonatomic) BOOL isPreGenerating;
@property (strong, nonatomic) dispatch_queue_t backgroundQueue;

- (void)sendMessage;
- (void)appendToChatLog:(NSString *)message fromUser:(BOOL)isUser;
- (void)startQuickGeneration:(NSString *)userInput;
- (void)continueGeneration;
- (void)appendContinuationToChatLog:(NSString *)continuation;
- (void)startBackgroundPreGeneration;
- (void)stopBackgroundPreGeneration;
- (void)clearChatHistory;

@end
