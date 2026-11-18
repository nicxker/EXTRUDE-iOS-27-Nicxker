// EXProcessDetailViewController.m

#import "EXProcessDetailViewController.h"
#import "EXProcessManager.h"

typedef NS_ENUM(NSInteger, EXDetailSection) {
    EXDetailSectionIdentity = 0,
    EXDetailSectionResources,
    EXDetailSectionTiming,
    EXDetailSectionMach,
    EXDetailSectionActions,
    EXDetailSectionCount,
};

@interface EXProcessDetailViewController ()

@property (nonatomic, strong) EXProcessInfo *processInfo;
@property (nonatomic, strong) NSDictionary *detailedInfo;
@property (nonatomic, strong) NSArray<NSArray<NSDictionary *> *> *sections;

@end

@implementation EXProcessDetailViewController

- (instancetype)initWithProcessInfo:(EXProcessInfo *)processInfo {
    self = [super initWithStyle:UITableViewStyleInsetGrouped];
    if (self) {
        _processInfo = processInfo;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = self.processInfo.name;
    self.view.backgroundColor = [UIColor colorWithRed:0.05 green:0.05 blue:0.08 alpha:1.0];
    self.tableView.separatorColor = [UIColor colorWithWhite:0.2 alpha:1.0];
    
    // Fetch detailed info
    self.detailedInfo = [[EXProcessManager sharedManager] detailedInfoForPID:self.processInfo.pid];
    
    [self buildSections];
    
    // Refresh button
    UIBarButtonItem *refreshButton = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"arrow.clockwise"]
                                                                     style:UIBarButtonItemStylePlain
                                                                    target:self
                                                                    action:@selector(refresh)];
    self.navigationItem.rightBarButtonItem = refreshButton;
}

- (void)refresh {
    self.detailedInfo = [[EXProcessManager sharedManager] detailedInfoForPID:self.processInfo.pid];
    [self buildSections];
    [self.tableView reloadData];
}

- (void)buildSections {
    NSMutableArray *sectionData = [NSMutableArray array];
    
    // Section 0: Identity
    NSMutableArray *identityRows = [NSMutableArray array];
    [identityRows addObject:@{@"title": @"Name", @"value": self.processInfo.name ?: @"—"}];
    [identityRows addObject:@{@"title": @"PID", @"value": [NSString stringWithFormat:@"%d", self.processInfo.pid]}];
    
    if (self.detailedInfo[@"ppid"]) {
        [identityRows addObject:@{@"title": @"Parent PID", @"value": [self.detailedInfo[@"ppid"] stringValue]}];
    }
    if (self.detailedInfo[@"pgid"]) {
        [identityRows addObject:@{@"title": @"Process Group", @"value": [self.detailedInfo[@"pgid"] stringValue]}];
    }
    
    [identityRows addObject:@{@"title": @"User", @"value": [self.processInfo ownerName]}];
    [identityRows addObject:@{@"title": @"UID", @"value": [NSString stringWithFormat:@"%d", self.processInfo.uid]}];
    
    if (self.detailedInfo[@"gid"]) {
        [identityRows addObject:@{@"title": @"GID", @"value": [self.detailedInfo[@"gid"] stringValue]}];
    }
    
    [identityRows addObject:@{@"title": @"Path", @"value": self.processInfo.path ?: @"(unknown)", @"copyable": @YES}];
    [identityRows addObject:@{@"title": @"Status", @"value": self.processInfo.isSuspended ? @"Suspended" : @"Running"}];
    
    if (self.detailedInfo[@"nice"]) {
        [identityRows addObject:@{@"title": @"Nice", @"value": [self.detailedInfo[@"nice"] stringValue]}];
    }
    if (self.detailedInfo[@"priority"]) {
        [identityRows addObject:@{@"title": @"Priority", @"value": [self.detailedInfo[@"priority"] stringValue]}];
    }
    
    [sectionData addObject:identityRows];
    
    // Section 1: Resources
    NSMutableArray *resourceRows = [NSMutableArray array];
    [resourceRows addObject:@{@"title": @"Resident Memory", @"value": [self.processInfo formattedMemory]}];
    
    if (self.detailedInfo[@"virtual_size"]) {
        uint64_t vsize = [self.detailedInfo[@"virtual_size"] unsignedLongLongValue];
        [resourceRows addObject:@{@"title": @"Virtual Memory", @"value": [self formatBytes:vsize]}];
    }
    if (self.detailedInfo[@"threadnum"]) {
        [resourceRows addObject:@{@"title": @"Threads", @"value": [self.detailedInfo[@"threadnum"] stringValue]}];
    }
    if (self.detailedInfo[@"numrunning"]) {
        [resourceRows addObject:@{@"title": @"Running Threads", @"value": [self.detailedInfo[@"numrunning"] stringValue]}];
    }
    if (self.detailedInfo[@"faults"]) {
        [resourceRows addObject:@{@"title": @"Page Faults", @"value": [self formatNumber:self.detailedInfo[@"faults"]]}];
    }
    if (self.detailedInfo[@"pageins"]) {
        [resourceRows addObject:@{@"title": @"Page Ins", @"value": [self formatNumber:self.detailedInfo[@"pageins"]]}];
    }
    if (self.detailedInfo[@"cow_faults"]) {
        [resourceRows addObject:@{@"title": @"CoW Faults", @"value": [self formatNumber:self.detailedInfo[@"cow_faults"]]}];
    }
    
    [sectionData addObject:resourceRows];
    
    // Section 2: Timing
    NSMutableArray *timingRows = [NSMutableArray array];
    if (self.detailedInfo[@"start_time"]) {
        NSTimeInterval startSec = [self.detailedInfo[@"start_time"] doubleValue];
        NSDate *startDate = [NSDate dateWithTimeIntervalSince1970:startSec];
        NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
        fmt.dateStyle = NSDateFormatterMediumStyle;
        fmt.timeStyle = NSDateFormatterMediumStyle;
        [timingRows addObject:@{@"title": @"Started", @"value": [fmt stringFromDate:startDate]}];
        
        NSTimeInterval uptime = [[NSDate date] timeIntervalSinceDate:startDate];
        [timingRows addObject:@{@"title": @"Uptime", @"value": [self formatDuration:uptime]}];
    }
    if (self.detailedInfo[@"total_user_time"]) {
        uint64_t userNs = [self.detailedInfo[@"total_user_time"] unsignedLongLongValue];
        [timingRows addObject:@{@"title": @"User CPU Time", @"value": [self formatNanoseconds:userNs]}];
    }
    if (self.detailedInfo[@"total_system_time"]) {
        uint64_t sysNs = [self.detailedInfo[@"total_system_time"] unsignedLongLongValue];
        [timingRows addObject:@{@"title": @"System CPU Time", @"value": [self formatNanoseconds:sysNs]}];
    }
    
    [sectionData addObject:timingRows];
    
    // Section 3: Mach / IPC
    NSMutableArray *machRows = [NSMutableArray array];
    if (self.detailedInfo[@"messages_sent"]) {
        [machRows addObject:@{@"title": @"Mach Messages Sent", @"value": [self formatNumber:self.detailedInfo[@"messages_sent"]]}];
    }
    if (self.detailedInfo[@"messages_received"]) {
        [machRows addObject:@{@"title": @"Mach Messages Received", @"value": [self formatNumber:self.detailedInfo[@"messages_received"]]}];
    }
    if (self.detailedInfo[@"syscalls_mach"]) {
        [machRows addObject:@{@"title": @"Mach Syscalls", @"value": [self formatNumber:self.detailedInfo[@"syscalls_mach"]]}];
    }
    if (self.detailedInfo[@"syscalls_unix"]) {
        [machRows addObject:@{@"title": @"Unix Syscalls", @"value": [self formatNumber:self.detailedInfo[@"syscalls_unix"]]}];
    }
    if (self.detailedInfo[@"csw"]) {
        [machRows addObject:@{@"title": @"Context Switches", @"value": [self formatNumber:self.detailedInfo[@"csw"]]}];
    }
    
    [sectionData addObject:machRows];
    
    // Section 4: Actions (virtual)
    [sectionData addObject:@[
        @{@"title": @"Copy Path", @"action": @"copyPath"},
        @{@"title": @"Open in Filza", @"action": @"openFilza"},
        @{@"title": self.processInfo.isSuspended ? @"Resume Process" : @"Pause Process", @"action": @"togglePause"},
        @{@"title": @"Send SIGTERM", @"action": @"sigterm"},
        @{@"title": @"Kill Process (SIGKILL)", @"action": @"kill", @"destructive": @YES},
    ]];
    
    self.sections = sectionData;
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.sections[section].count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case EXDetailSectionIdentity: return @"Identity";
        case EXDetailSectionResources: return @"Resources";
        case EXDetailSectionTiming: return @"Timing";
        case EXDetailSectionMach: return @"Mach / IPC";
        case EXDetailSectionActions: return @"Actions";
        default: return nil;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *row = self.sections[indexPath.section][indexPath.row];
    
    if (indexPath.section == EXDetailSectionActions) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ActionCell"];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"ActionCell"];
        }
        cell.backgroundColor = [UIColor colorWithRed:0.10 green:0.10 blue:0.14 alpha:1.0];
        cell.textLabel.text = row[@"title"];
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
        
        if ([row[@"destructive"] boolValue]) {
            cell.textLabel.textColor = [UIColor systemRedColor];
            cell.textLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightBold];
        } else {
            cell.textLabel.textColor = [UIColor systemBlueColor];
            cell.textLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
        }
        
        return cell;
    }
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DetailCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"DetailCell"];
    }
    
    cell.backgroundColor = [UIColor colorWithRed:0.10 green:0.10 blue:0.14 alpha:1.0];
    cell.textLabel.text = row[@"title"];
    cell.textLabel.textColor = [UIColor lightGrayColor];
    cell.textLabel.font = [UIFont systemFontOfSize:14];
    cell.detailTextLabel.text = row[@"value"];
    cell.detailTextLabel.textColor = [UIColor whiteColor];
    cell.detailTextLabel.font = [UIFont monospacedSystemFontOfSize:13 weight:UIFontWeightMedium];
    cell.detailTextLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
    cell.selectionStyle = [row[@"copyable"] boolValue] ? UITableViewCellSelectionStyleDefault : UITableViewCellSelectionStyleNone;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSDictionary *row = self.sections[indexPath.section][indexPath.row];
    
    // Copy on tap for copyable rows
    if ([row[@"copyable"] boolValue]) {
        [UIPasteboard generalPasteboard].string = row[@"value"];
        [self showToast:@"Copied to clipboard"];
        return;
    }
    
    // Handle actions
    NSString *action = row[@"action"];
    if (!action) return;
    
    if ([action isEqualToString:@"copyPath"]) {
        [UIPasteboard generalPasteboard].string = self.processInfo.path;
        [self showToast:@"Path copied"];
    }
    else if ([action isEqualToString:@"openFilza"]) {
        NSString *dirPath = [self.processInfo.path stringByDeletingLastPathComponent];
        NSString *filzaURL = [NSString stringWithFormat:@"filza://view%@", dirPath];
        NSURL *url = [NSURL URLWithString:[filzaURL stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
        if (url) {
            [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
        }
    }
    else if ([action isEqualToString:@"togglePause"]) {
        if (self.processInfo.isSuspended) {
            [[EXProcessManager sharedManager] resumeProcessWithPID:self.processInfo.pid];
            [self showToast:@"Process resumed"];
        } else {
            [[EXProcessManager sharedManager] suspendProcessWithPID:self.processInfo.pid];
            [self showToast:@"Process paused"];
        }
        self.processInfo.isSuspended = !self.processInfo.isSuspended;
        [self buildSections];
        [self.tableView reloadData];
    }
    else if ([action isEqualToString:@"sigterm"]) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Send SIGTERM"
                                                                      message:[NSString stringWithFormat:@"Send SIGTERM to %@ (PID %d)?", self.processInfo.name, self.processInfo.pid]
                                                               preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
        [alert addAction:[UIAlertAction actionWithTitle:@"Send" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *a) {
            [[EXProcessManager sharedManager] sendSignal:SIGTERM toProcessWithPID:self.processInfo.pid];
            [self.navigationController popViewControllerAnimated:YES];
        }]];
        [self presentViewController:alert animated:YES completion:nil];
    }
    else if ([action isEqualToString:@"kill"]) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Kill Process"
                                                                      message:[NSString stringWithFormat:@"Force kill %@ (PID %d)?\n\nThis cannot be undone.", self.processInfo.name, self.processInfo.pid]
                                                               preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
        [alert addAction:[UIAlertAction actionWithTitle:@"Kill" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *a) {
            [[EXProcessManager sharedManager] killProcessWithPID:self.processInfo.pid];
            [self.navigationController popViewControllerAnimated:YES];
        }]];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

#pragma mark - Helpers

- (NSString *)formatBytes:(uint64_t)bytes {
    double b = (double)bytes;
    if (b < 1024) return [NSString stringWithFormat:@"%.0f B", b];
    if (b < 1024 * 1024) return [NSString stringWithFormat:@"%.1f KB", b / 1024.0];
    if (b < 1024 * 1024 * 1024) return [NSString stringWithFormat:@"%.1f MB", b / (1024.0 * 1024.0)];
    return [NSString stringWithFormat:@"%.2f GB", b / (1024.0 * 1024.0 * 1024.0)];
}

- (NSString *)formatNumber:(NSNumber *)num {
    NSNumberFormatter *fmt = [[NSNumberFormatter alloc] init];
    fmt.numberStyle = NSNumberFormatterDecimalStyle;
    return [fmt stringFromNumber:num] ?: @"—";
}

- (NSString *)formatDuration:(NSTimeInterval)seconds {
    int days = (int)(seconds / 86400);
    int hours = ((int)seconds % 86400) / 3600;
    int mins = ((int)seconds % 3600) / 60;
    int secs = (int)seconds % 60;
    
    if (days > 0) return [NSString stringWithFormat:@"%dd %dh %dm", days, hours, mins];
    if (hours > 0) return [NSString stringWithFormat:@"%dh %dm %ds", hours, mins, secs];
    if (mins > 0) return [NSString stringWithFormat:@"%dm %ds", mins, secs];
    return [NSString stringWithFormat:@"%ds", secs];
}

- (NSString *)formatNanoseconds:(uint64_t)ns {
    double seconds = ns / 1000000000.0;
    return [self formatDuration:seconds];
}

- (void)showToast:(NSString *)message {
    UILabel *toast = [[UILabel alloc] init];
    toast.text = message;
    toast.textColor = [UIColor whiteColor];
    toast.backgroundColor = [UIColor colorWithWhite:0.2 alpha:0.9];
    toast.textAlignment = NSTextAlignmentCenter;
    toast.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    toast.layer.cornerRadius = 10;
    toast.clipsToBounds = YES;
    toast.alpha = 0;
    [toast sizeToFit];
    
    CGRect frame = toast.frame;
    frame.size.width += 32;
    frame.size.height += 16;
    frame.origin.x = (self.view.bounds.size.width - frame.size.width) / 2;
    frame.origin.y = self.view.bounds.size.height - 120;
    toast.frame = frame;
    
    [self.view addSubview:toast];
    
    [UIView animateWithDuration:0.3 animations:^{
        toast.alpha = 1;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.3 delay:1.5 options:0 animations:^{
            toast.alpha = 0;
        } completion:^(BOOL finished) {
            [toast removeFromSuperview];
        }];
    }];
}

@end
