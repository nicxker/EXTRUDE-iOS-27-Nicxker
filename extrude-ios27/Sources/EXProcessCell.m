// EXProcessCell.m

#import "EXProcessCell.h"

@interface EXProcessCell ()

@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *pidLabel;
@property (nonatomic, strong) UILabel *pathLabel;
@property (nonatomic, strong) UILabel *memLabel;
@property (nonatomic, strong) UIView *statusDot;
@property (nonatomic, strong) UIImageView *iconView;

@end

@implementation EXProcessCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        UIView *selectedBg = [[UIView alloc] init];
        selectedBg.backgroundColor = [UIColor colorWithWhite:0.15 alpha:1.0];
        self.selectedBackgroundView = selectedBg;
        
        // Status dot
        self.statusDot = [[UIView alloc] init];
        self.statusDot.translatesAutoresizingMaskIntoConstraints = NO;
        self.statusDot.layer.cornerRadius = 4;
        [self.contentView addSubview:self.statusDot];
        
        // Icon
        self.iconView = [[UIImageView alloc] init];
        self.iconView.translatesAutoresizingMaskIntoConstraints = NO;
        self.iconView.tintColor = [UIColor systemBlueColor];
        self.iconView.contentMode = UIViewContentModeScaleAspectFit;
        [self.contentView addSubview:self.iconView];
        
        // Name label
        self.nameLabel = [[UILabel alloc] init];
        self.nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
        self.nameLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
        self.nameLabel.textColor = [UIColor whiteColor];
        [self.contentView addSubview:self.nameLabel];
        
        // PID label
        self.pidLabel = [[UILabel alloc] init];
        self.pidLabel.translatesAutoresizingMaskIntoConstraints = NO;
        self.pidLabel.font = [UIFont monospacedSystemFontOfSize:11 weight:UIFontWeightMedium];
        self.pidLabel.textColor = [UIColor systemCyanColor];
        [self.contentView addSubview:self.pidLabel];
        
        // Path label
        self.pathLabel = [[UILabel alloc] init];
        self.pathLabel.translatesAutoresizingMaskIntoConstraints = NO;
        self.pathLabel.font = [UIFont monospacedSystemFontOfSize:10 weight:UIFontWeightRegular];
        self.pathLabel.textColor = [UIColor secondaryLabelColor];
        self.pathLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
        [self.contentView addSubview:self.pathLabel];
        
        // Memory label (right side)
        self.memLabel = [[UILabel alloc] init];
        self.memLabel.translatesAutoresizingMaskIntoConstraints = NO;
        self.memLabel.font = [UIFont monospacedSystemFontOfSize:11 weight:UIFontWeightMedium];
        self.memLabel.textColor = [UIColor systemGreenColor];
        self.memLabel.textAlignment = NSTextAlignmentRight;
        [self.contentView addSubview:self.memLabel];
        
        // Layout constraints
        [NSLayoutConstraint activateConstraints:@[
            // Status dot
            [self.statusDot.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:12],
            [self.statusDot.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
            [self.statusDot.widthAnchor constraintEqualToConstant:8],
            [self.statusDot.heightAnchor constraintEqualToConstant:8],
            
            // Icon
            [self.iconView.leadingAnchor constraintEqualToAnchor:self.statusDot.trailingAnchor constant:8],
            [self.iconView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
            [self.iconView.widthAnchor constraintEqualToConstant:28],
            [self.iconView.heightAnchor constraintEqualToConstant:28],
            
            // Name
            [self.nameLabel.leadingAnchor constraintEqualToAnchor:self.iconView.trailingAnchor constant:10],
            [self.nameLabel.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:10],
            [self.nameLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.memLabel.leadingAnchor constant:-8],
            
            // PID badge
            [self.pidLabel.leadingAnchor constraintEqualToAnchor:self.nameLabel.leadingAnchor],
            [self.pidLabel.topAnchor constraintEqualToAnchor:self.nameLabel.bottomAnchor constant:2],
            
            // Path
            [self.pathLabel.leadingAnchor constraintEqualToAnchor:self.nameLabel.leadingAnchor],
            [self.pathLabel.topAnchor constraintEqualToAnchor:self.pidLabel.bottomAnchor constant:1],
            [self.pathLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.contentView.trailingAnchor constant:-16],
            
            // Memory (right aligned)
            [self.memLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-16],
            [self.memLabel.centerYAnchor constraintEqualToAnchor:self.nameLabel.centerYAnchor],
            [self.memLabel.widthAnchor constraintGreaterThanOrEqualToConstant:60],
        ]];
        
        // Accessory
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    return self;
}

- (void)configureWithProcess:(EXProcessInfo *)process {
    self.nameLabel.text = process.name;
    self.pidLabel.text = [NSString stringWithFormat:@"PID %d · %@", process.pid, [process ownerName]];
    self.pathLabel.text = process.path;
    self.memLabel.text = [process formattedMemory];
    
    // Status dot color
    if (process.isSuspended) {
        self.statusDot.backgroundColor = [UIColor systemOrangeColor];
    } else {
        self.statusDot.backgroundColor = [UIColor systemGreenColor];
    }
    
    // Icon based on process type
    if ([process.path containsString:@"/Applications/"]) {
        self.iconView.image = [UIImage systemImageNamed:@"app.fill"];
        self.iconView.tintColor = [UIColor systemBlueColor];
    } else if ([process.path containsString:@"/usr/libexec/"] || [process.path containsString:@"/usr/sbin/"]) {
        self.iconView.image = [UIImage systemImageNamed:@"gearshape.fill"];
        self.iconView.tintColor = [UIColor systemGrayColor];
    } else if (process.isSystemProcess) {
        self.iconView.image = [UIImage systemImageNamed:@"lock.shield.fill"];
        self.iconView.tintColor = [UIColor systemYellowColor];
    } else {
        self.iconView.image = [UIImage systemImageNamed:@"terminal.fill"];
        self.iconView.tintColor = [UIColor systemTealColor];
    }
    
    // Suspended appearance
    self.nameLabel.alpha = process.isSuspended ? 0.5 : 1.0;
    self.iconView.alpha = process.isSuspended ? 0.5 : 1.0;
}

@end
