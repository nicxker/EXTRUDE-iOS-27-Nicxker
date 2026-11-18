// EXAppDelegate.m

#import "EXAppDelegate.h"
#import "EXProcessListViewController.h"

@implementation EXAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    
    EXProcessListViewController *processListVC = [[EXProcessListViewController alloc] init];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:processListVC];
    
    // Configure dark navigation bar appearance
   if (@available(iOS 13.0, *)) {
        UINavigationBarAppearance *appearance = [[UINavigationBarAppearance alloc] init];
        [appearance configureWithOpaqueBackground];
        appearance.backgroundColor = [UIColor colorWithRed:0.07 green:0.07 blue:0.10 alpha:1.0];
        appearance.titleTextAttributes = @{NSForegroundColorAttributeName: [UIColor whiteColor]};
        appearance.largeTitleTextAttributes = @{NSForegroundColorAttributeName: [UIColor whiteColor]};
        navController.navigationBar.standardAppearance = appearance;
        navController.navigationBar.scrollEdgeAppearance = appearance;
        navController.navigationBar.compactAppearance = appearance;
    }
    
    navController.navigationBar.barStyle = UIBarStyleBlack;
    navController.navigationBar.tintColor = [UIColor systemBlueColor];
    
    self.window.rootViewController = navController;
    [self.window makeKeyAndVisible];
    
    return YES;
}

@end
