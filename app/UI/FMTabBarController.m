#import "FMTabBarController.h"

#import "FMDesignSystem.h"
#import "FMGlassStyle.h"
#import "FMFontLibraryViewController.h"
#import "FMProfileLabViewController.h"
#import "FMSettingsViewController.h"

@interface FMTabItemView : UIControl
@property(nonatomic, strong) UIImageView *iconView;
@property(nonatomic, strong) UILabel *glyphLabel;
@property(nonatomic, strong) UILabel *titleLabel;
@end

@implementation FMTabItemView

- (instancetype)initWithTitle:(NSString *)title
                       symbol:(NSString *)symbol
                        glyph:(NSString *)glyph {
    self = [super initWithFrame:CGRectZero];
    if (self == nil) return nil;

    _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _titleLabel.text = title;
    _titleLabel.font = [UIFont systemFontOfSize:9.5 weight:UIFontWeightSemibold];
    _titleLabel.textAlignment = NSTextAlignmentCenter;

    if (glyph.length > 0) {
        _glyphLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _glyphLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _glyphLabel.text = glyph;
        _glyphLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightHeavy];
        _glyphLabel.textAlignment = NSTextAlignmentCenter;
        [self addSubview:_glyphLabel];
    } else {
        _iconView = [[UIImageView alloc] initWithFrame:CGRectZero];
        _iconView.translatesAutoresizingMaskIntoConstraints = NO;
        _iconView.contentMode = UIViewContentModeScaleAspectFit;
        _iconView.image = [UIImage systemImageNamed:symbol];
        [self addSubview:_iconView];
    }
    [self addSubview:_titleLabel];

    UIView *glyphView = _glyphLabel ?: _iconView;
    [NSLayoutConstraint activateConstraints:@[
        [glyphView.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
        [glyphView.topAnchor constraintEqualToAnchor:self.topAnchor constant:9],
        [glyphView.widthAnchor constraintEqualToConstant:22],
        [glyphView.heightAnchor constraintEqualToConstant:21],
        [_titleLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:2],
        [_titleLabel.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-2],
        [_titleLabel.topAnchor constraintEqualToAnchor:glyphView.bottomAnchor constant:1],
    ]];
    self.accessibilityLabel = title;
    self.accessibilityTraits = UIAccessibilityTraitButton;
    [self setSelected:NO];
    return self;
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    UIColor *color = selected ? UIColor.labelColor : UIColor.secondaryLabelColor;
    self.iconView.tintColor = color;
    self.glyphLabel.textColor = color;
    self.titleLabel.textColor = color;
    self.accessibilityTraits = selected
        ? (UIAccessibilityTraitButton | UIAccessibilityTraitSelected)
        : UIAccessibilityTraitButton;
}

@end

@interface FMLiquidTabBarView : UIView
@property(nonatomic, copy) void (^selectionHandler)(NSInteger index);
@property(nonatomic, readonly) NSInteger selectedIndex;
- (void)setSelectedIndex:(NSInteger)index animated:(BOOL)animated;
@end

@implementation FMLiquidTabBarView {
    UIVisualEffectView *_blur;
    UIView *_pill;
    NSArray<FMTabItemView *> *_items;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self == nil) return nil;
    self.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.55];
    self.layer.cornerRadius = 35;
    self.layer.cornerCurve = kCACornerCurveContinuous;
    self.layer.borderWidth = 1.0 / UIScreen.mainScreen.scale;
    self.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.95].CGColor;
    self.layer.shadowColor = [UIColor colorWithRed:0.32
                                              green:0.20
                                               blue:0.26
                                              alpha:1.0].CGColor;
    self.layer.shadowOpacity = 0.16;
    self.layer.shadowRadius = 24;
    self.layer.shadowOffset = CGSizeMake(0, 14);
    self.clipsToBounds = NO;

    _blur = [[UIVisualEffectView alloc]
        initWithEffect:[UIBlurEffect
            effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterialLight]];
    _blur.translatesAutoresizingMaskIntoConstraints = NO;
    _blur.layer.cornerRadius = 35;
    _blur.layer.cornerCurve = kCACornerCurveContinuous;
    _blur.clipsToBounds = YES;
    _blur.userInteractionEnabled = NO;
    [self addSubview:_blur];
    [NSLayoutConstraint activateConstraints:@[
        [_blur.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [_blur.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [_blur.topAnchor constraintEqualToAnchor:self.topAnchor],
        [_blur.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
    ]];

    _pill = [[UIView alloc] initWithFrame:CGRectZero];
    _pill.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.88];
    _pill.layer.cornerRadius = 27;
    _pill.layer.cornerCurve = kCACornerCurveContinuous;
    _pill.layer.borderWidth = 1.0 / UIScreen.mainScreen.scale;
    _pill.layer.borderColor = UIColor.whiteColor.CGColor;
    _pill.layer.shadowColor = FMGlassAccentColor().CGColor;
    _pill.layer.shadowOpacity = 0.16;
    _pill.layer.shadowRadius = 10;
    _pill.layer.shadowOffset = CGSizeMake(0, 4);
    _pill.userInteractionEnabled = NO;
    [self addSubview:_pill];

    NSArray<NSArray<NSString *> *> *specs = @[
        @[ FMLocalized(@"挂载"), @"link", @"" ],
        @[ FMLocalized(@"字体"), @"", @"Aa" ],
        @[ FMLocalized(@"字体库"), @"books.vertical", @"" ],
        @[ FMLocalized(@"设置"), @"gearshape", @"" ],
    ];
    NSMutableArray<FMTabItemView *> *items = [NSMutableArray array];
    [specs enumerateObjectsUsingBlock:^(NSArray<NSString *> *spec,
                                        NSUInteger index,
                                        BOOL *stop) {
        (void)stop;
        FMTabItemView *item = [[FMTabItemView alloc]
            initWithTitle:spec[0] symbol:spec[1] glyph:spec[2]];
        item.tag = (NSInteger)index;
        [item addTarget:self action:@selector(itemTapped:)
       forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:item];
        [items addObject:item];
    }];
    _items = items;
    _selectedIndex = 1;
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat width = self.bounds.size.width / (CGFloat)_items.count;
    [_items enumerateObjectsUsingBlock:^(FMTabItemView *item,
                                         NSUInteger index,
                                         BOOL *stop) {
        (void)stop;
        item.frame = CGRectMake(width * index, 4.0, width, self.bounds.size.height - 8.0);
    }];
    _pill.frame = CGRectInset(_items[(NSUInteger)_selectedIndex].frame, 4, 4);
}

- (void)itemTapped:(FMTabItemView *)sender {
    NSInteger index = sender.tag;
    if (index == _selectedIndex) return;
    [self setSelectedIndex:index animated:YES];
    if (self.selectionHandler != nil) self.selectionHandler(index);
}

- (void)setSelectedIndex:(NSInteger)index {
    [self setSelectedIndex:index animated:NO];
}

- (void)setSelectedIndex:(NSInteger)index animated:(BOOL)animated {
    if (index < 0 || index >= (NSInteger)_items.count) return;
    _selectedIndex = index;
    [_items enumerateObjectsUsingBlock:^(FMTabItemView *item,
                                         NSUInteger itemIndex,
                                         BOOL *stop) {
        (void)stop;
        [item setSelected:(NSInteger)itemIndex == index];
    }];
    void (^updates)(void) = ^{
        self->_pill.frame = CGRectInset(self->_items[(NSUInteger)index].frame, 4, 4);
    };
    if (animated && !UIAccessibilityIsReduceMotionEnabled()) {
        [UIView animateWithDuration:0.32
                              delay:0
             usingSpringWithDamping:0.82
              initialSpringVelocity:0.4
                            options:UIViewAnimationOptionBeginFromCurrentState |
                                    UIViewAnimationOptionAllowUserInteraction
                         animations:updates
                         completion:nil];
    } else {
        updates();
    }
}

@end

@interface FMTabBarController ()
@property(nonatomic, strong) id<FMProfileWorkspace> workspace;
@property(nonatomic, strong) NSArray<UINavigationController *> *controllers;
@property(nonatomic, strong) FMLiquidTabBarView *tabBar;
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
                                             dismissalHandler:^{
            [weakSelf switchToIndex:1 animated:NO];
        }];
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
        navigation.view.backgroundColor = UIColor.clearColor;
        navigation.additionalSafeAreaInsets = UIEdgeInsetsMake(0, 0, 92, 0);
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

    self.tabBar = [[FMLiquidTabBarView alloc] initWithFrame:CGRectZero];
    self.tabBar.translatesAutoresizingMaskIntoConstraints = NO;
    self.tabBar.selectionHandler = ^(NSInteger index) {
        [weakSelf switchToIndex:index animated:YES];
    };
    [self.view addSubview:self.tabBar];
    [NSLayoutConstraint activateConstraints:@[
        [self.tabBar.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16],
        [self.tabBar.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-16],
        [self.tabBar.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor
                                                 constant:-4],
        [self.tabBar.heightAnchor constraintEqualToConstant:70],
    ]];

    [self switchToIndex:self.selectedIndex animated:NO];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.view bringSubviewToFront:self.tabBar];
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
