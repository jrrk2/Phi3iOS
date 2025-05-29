#import "SettingsViewController.h"

@interface SliderTableViewCell : UITableViewCell
@property (strong, nonatomic) UILabel *titleLabel;
@property (strong, nonatomic) UILabel *valueLabel;
@property (strong, nonatomic) UISlider *slider;
@property (copy, nonatomic) void(^valueChangedBlock)(float value);
@end

@implementation SliderTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.titleLabel.font = [UIFont systemFontOfSize:16];
    [self.contentView addSubview:self.titleLabel];
    
    self.valueLabel = [[UILabel alloc] init];
    self.valueLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.valueLabel.font = [UIFont systemFontOfSize:16];
    self.valueLabel.textColor = [UIColor systemBlueColor];
    self.valueLabel.textAlignment = NSTextAlignmentRight;
    [self.contentView addSubview:self.valueLabel];
    
    self.slider = [[UISlider alloc] init];
    self.slider.translatesAutoresizingMaskIntoConstraints = NO;
    [self.slider addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    [self.contentView addSubview:self.slider];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.titleLabel.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:8],
        [self.titleLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:16],
        [self.titleLabel.trailingAnchor constraintEqualToAnchor:self.valueLabel.leadingAnchor constant:-8],
        
        [self.valueLabel.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:8],
        [self.valueLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-16],
        [self.valueLabel.widthAnchor constraintEqualToConstant:60],
        
        [self.slider.topAnchor constraintEqualToAnchor:self.titleLabel.bottomAnchor constant:8],
        [self.slider.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:16],
        [self.slider.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-16],
        [self.slider.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-8]
    ]];
}

- (void)sliderValueChanged:(UISlider *)slider {
    if (self.valueChangedBlock) {
        self.valueChangedBlock(slider.value);
    }
}

@end

@interface SettingsViewController () <UITableViewDataSource, UITableViewDelegate>
@end

@implementation SettingsViewController

static SettingsViewController *sharedInstance = nil;

+ (instancetype)sharedSettings {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[SettingsViewController alloc] init];
        [sharedInstance loadSettings];
    });
    return sharedInstance;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Generation Settings";
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    
    // Add navigation buttons
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonTapped)];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Reset" style:UIBarButtonItemStylePlain target:self action:@selector(resetButtonTapped)];
    
    [self setupTableView];
    [self loadSettings];
}

- (void)setupTableView {
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.tableView registerClass:[SliderTableViewCell class] forCellReuseIdentifier:@"SliderCell"];
    [self.view addSubview:self.tableView];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.tableView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [self.tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
    ]];
}

- (void)doneButtonTapped {
    [self saveSettings];
    if (self.delegate && [self.delegate respondsToSelector:@selector(settingsDidChange)]) {
        [self.delegate settingsDidChange];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)resetButtonTapped {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Reset Settings"
                                                                   message:@"Reset all settings to default values?"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Reset" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [self resetToDefaults];
        [self.tableView reloadData];
    }]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)resetToDefaults {
    self.maxTokens = 100;
    self.maxLength = 512;
    self.temperature = 0.7;
    self.topP = 0.9;
    self.repetitionPenalty = 1.1;
}

- (void)saveSettings {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:self.maxTokens forKey:@"maxTokens"];
    [defaults setInteger:self.maxLength forKey:@"maxLength"];
    [defaults setDouble:self.temperature forKey:@"temperature"];
    [defaults setDouble:self.topP forKey:@"topP"];
    [defaults setInteger:self.repetitionPenalty forKey:@"repetitionPenalty"];
    [defaults synchronize];
}

- (void)loadSettings {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    // Load with defaults if not set
    if (![defaults objectForKey:@"maxTokens"]) {
        [self resetToDefaults];
        [self saveSettings];
    } else {
        self.maxTokens = [defaults integerForKey:@"maxTokens"];
        self.maxLength = [defaults integerForKey:@"maxLength"];
        self.temperature = [defaults doubleForKey:@"temperature"];
        self.topP = [defaults doubleForKey:@"topP"];
        self.repetitionPenalty = [defaults integerForKey:@"repetitionPenalty"];
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2; // Generation Limits & Quality Settings
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return section == 0 ? 2 : 3; // Section 0: 2 items, Section 1: 3 items
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return section == 0 ? @"Generation Limits" : @"Quality Settings";
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section == 0) {
        return @"Max Tokens: Maximum number of tokens to generate per response\nMax Length: Maximum total sequence length";
    } else {
        return @"Temperature: Controls randomness (0.0 = deterministic, 1.0 = very random)\nTop P: Nucleus sampling threshold\nRepetition Penalty: Reduces repetitive text";
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SliderTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SliderCell" forIndexPath:indexPath];
    
    if (indexPath.section == 0) {
        // Generation Limits
        if (indexPath.row == 0) {
            // Max Tokens
            cell.titleLabel.text = @"Max Tokens";
            cell.slider.minimumValue = 10;
            cell.slider.maximumValue = 500;
            cell.slider.value = self.maxTokens;
            cell.valueLabel.text = [NSString stringWithFormat:@"%ld", (long)self.maxTokens];
            
            __weak SettingsViewController *weakSelf = self;
            cell.valueChangedBlock = ^(float value) {
                weakSelf.maxTokens = (NSInteger)value;
                cell.valueLabel.text = [NSString stringWithFormat:@"%ld", (long)weakSelf.maxTokens];
            };
        } else {
            // Max Length
            cell.titleLabel.text = @"Max Length";
            cell.slider.minimumValue = 128;
            cell.slider.maximumValue = 2048;
            cell.slider.value = self.maxLength;
            cell.valueLabel.text = [NSString stringWithFormat:@"%ld", (long)self.maxLength];
            
            __weak SettingsViewController *weakSelf = self;
            cell.valueChangedBlock = ^(float value) {
                weakSelf.maxLength = (NSInteger)value;
                cell.valueLabel.text = [NSString stringWithFormat:@"%ld", (long)weakSelf.maxLength];
            };
        }
    } else {
        // Quality Settings
        if (indexPath.row == 0) {
            // Temperature
            cell.titleLabel.text = @"Temperature";
            cell.slider.minimumValue = 0.0;
            cell.slider.maximumValue = 2.0;
            cell.slider.value = self.temperature;
            cell.valueLabel.text = [NSString stringWithFormat:@"%.2f", self.temperature];
            
            __weak SettingsViewController *weakSelf = self;
            cell.valueChangedBlock = ^(float value) {
                weakSelf.temperature = value;
                cell.valueLabel.text = [NSString stringWithFormat:@"%.2f", weakSelf.temperature];
            };
        } else if (indexPath.row == 1) {
            // Top P
            cell.titleLabel.text = @"Top P";
            cell.slider.minimumValue = 0.1;
            cell.slider.maximumValue = 1.0;
            cell.slider.value = self.topP;
            cell.valueLabel.text = [NSString stringWithFormat:@"%.2f", self.topP];
            
            __weak SettingsViewController *weakSelf = self;
            cell.valueChangedBlock = ^(float value) {
                weakSelf.topP = value;
                cell.valueLabel.text = [NSString stringWithFormat:@"%.2f", weakSelf.topP];
            };
        } else {
            // Repetition Penalty
            cell.titleLabel.text = @"Repetition Penalty";
            cell.slider.minimumValue = 1.0;
            cell.slider.maximumValue = 2.0;
            cell.slider.value = self.repetitionPenalty / 10.0; // Scale for slider
            cell.valueLabel.text = [NSString stringWithFormat:@"%.1f", self.repetitionPenalty / 10.0];
            
            __weak SettingsViewController *weakSelf = self;
            cell.valueChangedBlock = ^(float value) {
                weakSelf.repetitionPenalty = (NSInteger)(value * 10); // Scale back
                cell.valueLabel.text = [NSString stringWithFormat:@"%.1f", value];
            };
        }
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 80;
}

@end
