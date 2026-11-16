#import "FMTabBarController.h"

#import "FMDesignSystem.h"
#import "FMGlassStyle.h"
#import "FMFontLibraryViewController.h"
#import "FMProfileLabViewController.h"
#import "FMSettingsViewController.h"

// Narrow Objective-C declaration for the Swift bridge. Both implementations
// link into FontManager; no generated Swift header or runtime lookup is needed.
@interface FMTheseusTabBar : UIView
- (instancetype)initWithTitles:(NSArray<NSString *> *)titles;
@property(nonatomic, copy) void (^selectionHandler)(NSInteger index);
@property(nonatomic, readonly) NSInteger selectedIndex;
- (void)setSelectedIndex:(NSInteger)index animated:(BOOL)animated;
- (void)markfontSetTransitioning:(BOOL)transitioning;
@end

@interface FMTabBarController () <UIGestureRecognizerDelegate, UINavigationControllerDelegate>
@property(nonatomic, strong) id<FMProfileWorkspace> workspace;
@property(nonatomic, strong) NSArray<UINavigationController *> *controllers;
@property(nonatomic, strong) FMTheseusTabBar *tabBar;
@property(nonatomic, strong) FMProfileLabViewController *fontController;
@property(nonatomic) NSInteger selectedIndex;
@end

@implementation FMTabBarController

- (instancetype)initWithWorkspace:(id<FMProfileWorkspace>)workspace {
    self = [super initWithNibName:nil bundle:nil];
    if (self != nil) {
        _workspace = workspace;
        _selectedIndex = 1;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.clearColor;
    self.view.accessibilityIdentifier = @"root_tabs";

    FMProfileLabViewController *font =
        [[FMProfileLabViewController alloc] initWithWorkspace:self.workspace];
    self.fontController = font;

    __weak typeof(self) weakSelf = self;
    FMFontLibraryViewController *library =
        [[FMFontLibraryViewController alloc] initWithWorkspace:self.workspace
                                                 applyHandler:^(NSString *profileID) {
            [weakSelf switchToIndex:1 animated:NO];
            [weakSelf.fontController applyProfileFromLibrary:profileID];
        }
                                             dismissalHandler:nil];
    FMSettingsViewController *settings =
        [[FMSettingsViewController alloc] initWithWorkspace:self.workspace
                                           dismissalHandler:nil];
    UIViewController *mount = FMCreateMountPathsViewController(self.workspace);

    NSArray<UIViewController *> *roots = @[ mount, font, library, settings ];
    NSMutableArray<UINavigationController *> *navigations = [NSMutableArray array];
    for (UIViewController *root in roots) {
        UINavigationController *navigation =
            [[UINavigationController alloc] initWithRootViewController:root];
        FMConfigureNavigationController(navigation);
        navigation.delegate = self;
        UIView *stackBackground = FMGlassBackgroundView();
        stackBackground.translatesAutoresizingMaskIntoConstraints = NO;
        [navigation.view insertSubview:stackBackground atIndex:0];
        [NSLayoutConstraint activateConstraints:@[
            [stackBackground.leadingAnchor constraintEqualToAnchor:navigation.view.leadingAnchor],
            [stackBackground.trailingAnchor constraintEqualToAnchor:navigation.view.trailingAnchor],
            [stackBackground.topAnchor constraintEqualToAnchor:navigation.view.topAnchor],
            [stackBackground.bottomAnchor constraintEqualToAnchor:navigation.view.bottomAnchor],
        ]];
        navigation.view.backgroundColor = UIColor.clearColor;
        navigation.additionalSafeAreaInsets = UIEdgeInsetsMake(0, 0, 100, 0);
        navigation.view.translatesAutoresizingMaskIntoConstraints = NO;
        [self addChildViewController:navigation];
        [self.view addSubview:navigation.view];
        [NSLayoutConstraint activateConstraints:@[
            [navigation.view.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
            [navigation.view.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
            [navigation.view.topAnchor constraintEqualToAnchor:self.view.topAnchor],
            [navigation.view.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        ]];
        [navigation didMoveToParentViewController:self];
        navigation.view.hidden = YES;
        [navigations addObject:navigation];
    }
    self.controllers = navigations;

    self.tabBar = [[FMTheseusTabBar alloc] initWithTitles:@[
        FMLocalized(@"挂载"), FMLocalized(@"字体"),
        FMLocalized(@"字体库"), FMLocalized(@"设置"),
    ]];
    self.tabBar.translatesAutoresizingMaskIntoConstraints = NO;
    self.tabBar.selectionHandler = ^(NSInteger index) {
        [weakSelf switchToIndex:index animated:YES];
    };
    [self.view addSubview:self.tabBar];
    [NSLayoutConstraint activateConstraints:@[
        [self.tabBar.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16],
        [self.tabBar.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-16],
        [self.tabBar.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor
                                                 constant:-14],
        [self.tabBar.heightAnchor constraintEqualToConstant:72],
    ]];

    [self installSwipeGestures];
    [self switchToIndex:self.selectedIndex animated:NO];
}

- (void)installSwipeGestures {
    // UINavigationController owns the interactive edge-pop gesture. A second
    // full-screen swipe recognizer must not compete with it during back.
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
       shouldReceiveTouch:(UITouch *)touch {
    (void)gestureRecognizer;
    // Theseus owns drags begun on the bar. Navigation owns page back gestures.
    return NO;
}

- (void)handleTabSwipe:(UISwipeGestureRecognizer *)gesture {
    if (self.selectedIndex < 0 || self.selectedIndex >= (NSInteger)self.controllers.count) return;
    UINavigationController *current = self.controllers[(NSUInteger)self.selectedIndex];
    if (current.viewControllers.count > 1) {
        // Inside a pushed page the same swipe means "go back".
        if (gesture.direction == UISwipeGestureRecognizerDirectionRight) {
            [current popViewControllerAnimated:YES];
        }
        return;
    }
    NSInteger delta = gesture.direction == UISwipeGestureRecognizerDirectionLeft ? 1 : -1;
    NSInteger next = self.selectedIndex + delta;
    if (next < 0 || next >= (NSInteger)self.controllers.count) return;
    [self switchToIndex:next animated:YES];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.view bringSubviewToFront:self.tabBar];
}

- (void)navigationController:(UINavigationController *)navigationController
       willShowViewController:(UIViewController *)viewController
                    animated:(BOOL)animated {
    (void)navigationController;
    (void)viewController;
    (void)animated;
    [self.tabBar markfontSetTransitioning:YES];
}

- (void)navigationController:(UINavigationController *)navigationController
        didShowViewController:(UIViewController *)viewController
                     animated:(BOOL)animated {
    (void)navigationController;
    (void)viewController;
    (void)animated;
    [self.tabBar markfontSetTransitioning:NO];
}

- (void)switchToIndex:(NSInteger)index animated:(BOOL)animated {
    if (index < 0 || index >= (NSInteger)self.controllers.count) return;
    self.selectedIndex = index;
    [self.controllers enumerateObjectsUsingBlock:^(UINavigationController *controller,
                                                   NSUInteger controllerIndex,
                                                   BOOL *stop) {
        (void)stop;
        controller.view.hidden = (NSInteger)controllerIndex != index;
    }];
    [self.tabBar setSelectedIndex:index animated:animated];
    if (animated) {
        [[[UISelectionFeedbackGenerator alloc] init] selectionChanged];
    }
}

@end
