#import "FMAppDelegate.h"

#import "FMDesignSystem.h"
#import "FMDeviceProfileWorkspace.h"
#import "FMFontPackageImportSession.h"
#import "FMProfileLabViewController.h"
#import "FMTabBarController.h"
#import "FMGlassStyle.h"
#import "FMLocalization.h"

@interface FMAppDelegate ()
- (UIViewController *)makeRootViewController;
- (void)installRootViewControllerAnimated:(BOOL)animated;
- (void)languagePreferenceDidChange:(NSNotification *)notification;
@end

@implementation FMAppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary<UIApplicationLaunchOptionsKey, id> *)launchOptions {
    (void)application;
    (void)launchOptions;

    // No session can be active before the first UI is created. Remove only
    // Font Manager's exact temporary import directories left by an earlier
    // terminated process; Profiles and user-selected source files are outside
    // this root.
    [FMFontPackageImportSession discardAbandonedSessions:nil];

    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    self.window.tintColor = FMAccentColor();
    FMApplyAppearancePreferenceToWindow(self.window);

    [NSNotificationCenter.defaultCenter
        addObserver:self
           selector:@selector(languagePreferenceDidChange:)
               name:FMLanguagePreferenceDidChangeNotification()
             object:nil];
    [self installRootViewControllerAnimated:NO];
    [self.window makeKeyAndVisible];
    return YES;
}

- (UIViewController *)makeRootViewController {
    FMDeviceProfileWorkspace *workspace = [[FMDeviceProfileWorkspace alloc] init];
    FMTabBarController *tabs = [[FMTabBarController alloc] initWithWorkspace:workspace];
    UIView *background = FMGlassBackgroundView();
    background.frame = self.window.bounds;
    background.autoresizingMask = UIViewAutoresizingFlexibleWidth |
        UIViewAutoresizingFlexibleHeight;
    [self.window insertSubview:background atIndex:0];
    return tabs;
}

- (void)installRootViewControllerAnimated:(BOOL)animated {
    UIViewController *rootViewController = [self makeRootViewController];
    if (!animated || self.window.rootViewController == nil ||
        UIAccessibilityIsReduceMotionEnabled()) {
        self.window.rootViewController = rootViewController;
        return;
    }
    [UIView transitionWithView:self.window
                      duration:0.22
                       options:UIViewAnimationOptionTransitionCrossDissolve |
                               UIViewAnimationOptionAllowAnimatedContent
                    animations:^{
        self.window.rootViewController = rootViewController;
    }
                    completion:nil];
}

- (void)languagePreferenceDidChange:(NSNotification *)notification {
    (void)notification;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self installRootViewControllerAnimated:YES];
    });
}

@end
