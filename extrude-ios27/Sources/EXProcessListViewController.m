// EXProcessListViewController.m

#import "EXProcessListViewController.h"
#import "EXProcessDetailViewController.h"
#import "EXProcessManager.h"
#import "EXProcessInfo.h"
#import "EXProcessCell.h"

static NSString * const kCellID = @"EXProcessCell";

@interface EXProcessListViewController () <UITableViewDataSource, UITableViewDelegate, UISearchResultsUpdating>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UISearchController *searchController;
@property (nonatomic, strong) UISegmentedControl *filterSegment;
@property (nonatomic, strong) UILabel *countLabel;

@property (nonatomic, strong) NSArray<EXProcessInfo *> *processes;
@property (nonatomic, strong) NSTimer *refreshTimer;

@property (nonatomic, assign) EXProcessFilter currentFilter;
@property (nonatomic, assign) EXSortOrder currentSort;
@property (nonatomic, copy) NSString *searchText;

@end

@implementation EXProcessListViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Extrude";
    self.view.backgroundColor = [UIColor colorWithRed:0.05 green:0.05 blue:0.08 alpha:1.0];
    
    self.currentFilter = EXProcessFilterAll;
    self.currentSort = EXSortOrderName;
    self.searchText = @"";
    
    [self setupNavigationBar];
    [self setupFilterSegment];
    [self setupCountLabel];
    [self setupTableView];
    [self setupSearchController];
    
    [self refreshProcesses];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // Auto-refresh every 3 seconds
    self.refreshTimer = [NSTimer scheduledTimerWithTimeInterval:3.0
                                                        target:self
                                                      selector:@selector(refreshProcesses)
                                                      userInfo:nil
                                                       repeats:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.refreshTimer invalidate];
    self.refreshTimer = nil;
}

#pragma mark - Setup

- (void)setupNavigationBar {
    // Sort button (ActionSheet universal)
    UIBarButtonItem *sortButton = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"arrow.up.arrow.down"]
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:self
                                                                  action:@selector(showSortSheet)];
    
    // Refresh button
    UIBarButtonItem *refreshButton = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"arrow.clockwise"]
                                                                     style:UIBarButtonItemStylePlain
                                                                    target:self
                                                                    action:@selector(refreshProcesses)];
    
    self.navigationItem.rightBarButtonItems = @[refreshButton, sortButton];
    
    // Info button (left)
    UIBarButtonItem *infoButton = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"info.circle"]
                                                                  style:UIBarButtonItemStylePlain
                                                                 target:self
                                                                 action:@selector(showAbout)];
    self.navigationItem.leftBarButtonItem = infoButton;
}

- (void)showSortSheet {
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:@"Sort Processes By" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [sheet addAction:[UIAlertAction actionWithTitle:@"Name" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        self.currentSort = EXSortOrderName;
        [self refreshProcesses];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:@"PID" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        self.currentSort = EXSortOrderPID;
        [self refreshProcesses];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:@"Memory" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        self.currentSort = EXSortOrderMemory;
        [self refreshProcesses];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:@"CPU" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        self.currentSort = EXSortOrderCPU;
        [self refreshProcesses];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:sheet animated:YES completion:nil];
}
    // Sort button
    UIAction *sortByName = [UIAction actionWithTitle:@"Name" image:[UIImage systemImageNamed:@"textformat.abc"] identifier:nil handler:^(UIAction *action) {
        self.currentSort = EXSortOrderName;
        [self refreshProcesses];
    }];
    UIAction *sortByPID = [UIAction actionWithTitle:@"PID" image:[UIImage systemImageNamed:@"number"] identifier:nil handler:^(UIAction *action) {
        self.currentSort = EXSortOrderPID;
        [self refreshProcesses];
    }];
    UIAction *sortByMemory = [UIAction actionWithTitle:@"Memory" image:[UIImage systemImageNamed:@"memorychip"] identifier:nil handler:^(UIAction *action) {
        self.currentSort = EXSortOrderMemory;
        [self refreshProcesses];
    }];
    UIAction *sortByCPU = [UIAction actionWithTitle:@"CPU" image:[UIImage systemImageNamed:@"cpu"] identifier:nil handler:^(UIAction *action) {
        self.currentSort = EXSortOrderCPU;
        [self refreshProcesses];
    }];
    
    UIMenu *sortMenu = [UIMenu menuWithTitle:@"Sort By" children:@[sortByName, sortByPID, sortByMemory, sortByCPU]];
    UIBarButtonItem *sortButton = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"arrow.up.arrow.down"]
                                                                  menu:sortMenu];
    
    // Refresh button
    UIBarButtonItem *refreshButton = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"arrow.clockwise"]
                                                                     style:UIBarButtonItemStylePlain
                                                                    target:self
                                                                    action:@selector(refreshProcesses)];
    
    self.navigationItem.rightBarButtonItems = @[refreshButton, sortButton];
    
    // Info button (left)
    UIBarButtonItem *infoButton = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"info.circle"]
                                                                  style:UIBarButtonItemStylePlain
                                                                 target:self
                                                                 action:@selector(showAbout)];
    self.navigationItem.leftBarButtonItem = infoButton;
}

- (void)setupFilterSegment {
    self.filterSegment = [[UISegmentedControl alloc] initWithItems:@[@"All", @"User", @"System", @"Apps", @"Daemons"]];
    self.filterSegment.selectedSegmentIndex = 0;
    self.filterSegment.translatesAutoresizingMaskIntoConstraints = NO;
    
    // Style
    self.filterSegment.backgroundColor = [UIColor colorWithRed:0.12 green:0.12 blue:0.16 alpha:1.0];
    self.filterSegment.selectedSegmentTintColor = [UIColor systemBlueColor];
    [self.filterSegment setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor lightGrayColor]} forState:UIControlStateNormal];
    [self.filterSegment setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]} forState:UIControlStateSelected];
    
    [self.filterSegment addTarget:self action:@selector(filterChanged:) forControlEvents:UIControlEventValueChanged];
    
    [self.view addSubview:self.filterSegment];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.filterSegment.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:8],
        [self.filterSegment.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16],
        [self.filterSegment.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-16],
        [self.filterSegment.heightAnchor constraintEqualToConstant:32],
    ]];
}

- (void)setupCountLabel {
    self.countLabel = [[UILabel alloc] init];
    self.countLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.countLabel.font = [UIFont monospacedSystemFontOfSize:12 weight:UIFontWeightMedium];
    self.countLabel.textColor = [UIColor secondaryLabelColor];
    self.countLabel.textAlignment = NSTextAlignmentRight;
    self.countLabel.text = @"0 processes";
    
    [self.view addSubview:self.countLabel];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.countLabel.topAnchor constraintEqualToAnchor:self.filterSegment.bottomAnchor constant:6],
        [self.countLabel.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-16],
        [self.countLabel.heightAnchor constraintEqualToConstant:16],
    ]];
}

- (void)setupTableView {
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.separatorColor = [UIColor colorWithWhite:0.2 alpha:1.0];
    self.tableView.rowHeight = 68;
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    
    [self.tableView registerClass:[EXProcessCell class] forCellReuseIdentifier:kCellID];
    
    [self.view addSubview:self.tableView];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.tableView.topAnchor constraintEqualToAnchor:self.countLabel.bottomAnchor constant:4],
        [self.tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    ]];
}

- (void)setupSearchController {
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.searchResultsUpdater = self;
    self.searchController.obscuresBackgroundDuringPresentation = NO;
    self.searchController.searchBar.placeholder = @"Search processes, PIDs, paths...";
    self.searchController.searchBar.barStyle = UIBarStyleBlack;
    self.navigationItem.searchController = self.searchController;
    self.navigationItem.hidesSearchBarWhenScrolling = NO;
    self.definesPresentationContext = YES;
}

#pragma mark - Actions

- (void)filterChanged:(UISegmentedControl *)segment {
    self.currentFilter = (EXProcessFilter)segment.selectedSegmentIndex;
    [self refreshProcesses];
}

- (void)refreshProcesses {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSArray<EXProcessInfo *> *procs = [[EXProcessManager sharedManager]
                                           processesFilteredBy:self.currentFilter
                                           searchText:self.searchText
                                           sortOrder:self.currentSort];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.processes = procs;
            self.countLabel.text = [NSString stringWithFormat:@"%lu processes", (unsigned long)procs.count];
            [self.tableView reloadData];
        });
    });
}

- (void)showAbout {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Extrude"
                                                                  message:@"Process Manager for iOS 27.2\n\nInspired by hans32's Extrude.\nBuilt for rootless jailbreak environments.\n\nv1.0.0"
                                                           preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - UISearchResultsUpdating

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    self.searchText = searchController.searchBar.text ?: @"";
    [self refreshProcesses];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.processes.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    EXProcessCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellID forIndexPath:indexPath];
    
    if (indexPath.row < self.processes.count) {
        EXProcessInfo *proc = self.processes[indexPath.row];
        [cell configureWithProcess:proc];
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.row < self.processes.count) {
        EXProcessInfo *proc = self.processes[indexPath.row];
        EXProcessDetailViewController *detailVC = [[EXProcessDetailViewController alloc] initWithProcessInfo:proc];
        [self.navigationController pushViewController:detailVC animated:YES];
    }
}

- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView
    trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.row >= self.processes.count) return nil;
    
    EXProcessInfo *proc = self.processes[indexPath.row];
    
    // Kill action (red)
    UIContextualAction *killAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive
                                                                            title:@"Kill"
                                                                          handler:^(UIContextualAction *action, UIView *sourceView, void (^completionHandler)(BOOL)) {
        [self confirmKillProcess:proc completion:completionHandler];
    }];
    killAction.backgroundColor = [UIColor systemRedColor];
    killAction.image = [UIImage systemImageNamed:@"xmark.circle.fill"];
    
    // Pause/Resume action (orange/green)
    NSString *pauseTitle = proc.isSuspended ? @"Resume" : @"Pause";
    UIContextualAction *pauseAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal
                                                                             title:pauseTitle
                                                                           handler:^(UIContextualAction *action, UIView *sourceView, void (^completionHandler)(BOOL)) {
        BOOL success;
        if (proc.isSuspended) {
            success = [[EXProcessManager sharedManager] resumeProcessWithPID:proc.pid];
        } else {
            success = [[EXProcessManager sharedManager] suspendProcessWithPID:proc.pid];
        }
        [self refreshProcesses];
        completionHandler(success);
    }];
    pauseAction.backgroundColor = proc.isSuspended ? [UIColor systemGreenColor] : [UIColor systemOrangeColor];
    pauseAction.image = proc.isSuspended ? [UIImage systemImageNamed:@"play.circle.fill"] : [UIImage systemImageNamed:@"pause.circle.fill"];
    
    return [UISwipeActionsConfiguration configurationWithActions:@[killAction, pauseAction]];
}

- (void)confirmKillProcess:(EXProcessInfo *)proc completion:(void (^)(BOOL))completionHandler {
    NSString *message = [NSString stringWithFormat:@"Kill %@ (PID %d)?\n\nThis will forcefully terminate the process. Killing system processes may cause instability.",
                         proc.name, proc.pid];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Kill Process"
                                                                  message:message
                                                           preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        completionHandler(NO);
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Kill" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        BOOL success = [[EXProcessManager sharedManager] killProcessWithPID:proc.pid];
        [self refreshProcesses];
        completionHandler(success);
    }]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (UIContextMenuConfiguration *)tableView:(UITableView *)tableView
    contextMenuConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath
                                      point:(CGPoint)point {
    
    if (indexPath.row >= self.processes.count) return nil;
    
    EXProcessInfo *proc = self.processes[indexPath.row];
    
    return [UIContextMenuConfiguration configurationWithIdentifier:nil
                                                   previewProvider:nil
                                                    actionProvider:^UIMenu *(NSArray<UIMenuElement *> *suggestedActions) {
        
        // Copy Name
        UIAction *copyName = [UIAction actionWithTitle:@"Copy Name"
                                                 image:[UIImage systemImageNamed:@"doc.on.doc"]
                                            identifier:nil
                                               handler:^(UIAction *action) {
            [UIPasteboard generalPasteboard].string = proc.name;
        }];
        
        // Copy PID
        UIAction *copyPID = [UIAction actionWithTitle:@"Copy PID"
                                                image:[UIImage systemImageNamed:@"number"]
                                           identifier:nil
                                              handler:^(UIAction *action) {
            [UIPasteboard generalPasteboard].string = [NSString stringWithFormat:@"%d", proc.pid];
        }];
        
        // Copy Path
        UIAction *copyPath = [UIAction actionWithTitle:@"Copy Path"
                                                 image:[UIImage systemImageNamed:@"folder"]
                                            identifier:nil
                                               handler:^(UIAction *action) {
            [UIPasteboard generalPasteboard].string = proc.path;
        }];
        
        UIMenu *copyMenu = [UIMenu menuWithTitle:@"Copy" image:[UIImage systemImageNamed:@"doc.on.clipboard"] identifier:nil options:0 children:@[copyName, copyPID, copyPath]];
        
        // Open in Filza
        UIAction *openFilza = [UIAction actionWithTitle:@"Open in Filza"
                                                  image:[UIImage systemImageNamed:@"folder.badge.gearshape"]
                                             identifier:nil
                                                handler:^(UIAction *action) {
            NSString *dirPath = [proc.path stringByDeletingLastPathComponent];
            NSString *filzaURL = [NSString stringWithFormat:@"filza://view%@", dirPath];
            NSURL *url = [NSURL URLWithString:[filzaURL stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
            if (url) {
                [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
            }
        }];
        
        // Pause / Resume
        NSString *pauseTitle = proc.isSuspended ? @"Resume Process" : @"Pause Process";
        NSString *pauseImage = proc.isSuspended ? @"play.circle" : @"pause.circle";
        UIAction *pauseAction = [UIAction actionWithTitle:pauseTitle
                                                    image:[UIImage systemImageNamed:pauseImage]
                                               identifier:nil
                                                  handler:^(UIAction *action) {
            if (proc.isSuspended) {
                [[EXProcessManager sharedManager] resumeProcessWithPID:proc.pid];
            } else {
                [[EXProcessManager sharedManager] suspendProcessWithPID:proc.pid];
            }
            [self refreshProcesses];
        }];
        
        // Kill
        UIAction *killAction = [UIAction actionWithTitle:@"Kill Process"
                                                   image:[UIImage systemImageNamed:@"xmark.circle"]
                                              identifier:nil
                                                 handler:^(UIAction *action) {
            [self confirmKillProcess:proc completion:^(BOOL success) {}];
        }];
        killAction.attributes = UIMenuElementAttributesDestructive;
        
        return [UIMenu menuWithTitle:proc.name children:@[copyMenu, openFilza, pauseAction, killAction]];
    }];
}

@end
