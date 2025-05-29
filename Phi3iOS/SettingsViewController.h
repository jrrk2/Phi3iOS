#import <UIKit/UIKit.h>

@protocol SettingsDelegate <NSObject>
- (void)settingsDidChange;
@end

@interface SettingsViewController : UIViewController

@property (weak, nonatomic) id<SettingsDelegate> delegate;

// Settings properties
@property (nonatomic, assign) NSInteger maxTokens;
@property (nonatomic, assign) NSInteger maxLength;
@property (nonatomic, assign) double temperature;
@property (nonatomic, assign) double topP;
@property (nonatomic, assign) NSInteger repetitionPenalty;

// UI Elements
@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) NSMutableArray *settingsSections;

+ (instancetype)sharedSettings;
- (void)saveSettings;
- (void)loadSettings;
- (void)resetToDefaults;

@end