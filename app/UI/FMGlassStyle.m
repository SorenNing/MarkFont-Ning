#import "FMGlassStyle.h"

@interface FMLiquidGradientView : UIView
@property(nonatomic, copy) NSArray<CAGradientLayer *> *blobs;
@property(nonatomic, copy) NSArray<UIColor *> *resolvedColors;
@end

@implementation FMLiquidGradientView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self == nil) return nil;
    // Same hue family, one dark variant: the background darkens as a whole in
    // dark mode while the gradient pattern stays identical.
    self.backgroundColor = [UIColor colorWithDynamicProvider:
        ^UIColor *(UITraitCollection *traits) {
            return traits.userInterfaceStyle == UIUserInterfaceStyleDark
                ? [UIColor colorWithRed:0.106 green:0.098 blue:0.118 alpha:1.0]
                : [UIColor colorWithRed:0.929 green:0.914 blue:0.894 alpha:1.0];
        }];
    UIColor *blobWarm = [UIColor colorWithDynamicProvider:
        ^UIColor *(UITraitCollection *traits) {
            return traits.userInterfaceStyle == UIUserInterfaceStyleDark
                ? [UIColor colorWithRed:0.42 green:0.26 blue:0.18 alpha:1.0]
                : [UIColor colorWithRed:0.988 green:0.851 blue:0.749 alpha:1.0];
        }];
    UIColor *blobPink = [UIColor colorWithDynamicProvider:
        ^UIColor *(UITraitCollection *traits) {
            return traits.userInterfaceStyle == UIUserInterfaceStyleDark
                ? [UIColor colorWithRed:0.40 green:0.20 blue:0.28 alpha:1.0]
                : [UIColor colorWithRed:0.988 green:0.816 blue:0.867 alpha:1.0];
        }];
    UIColor *blobMint = [UIColor colorWithDynamicProvider:
        ^UIColor *(UITraitCollection *traits) {
            return traits.userInterfaceStyle == UIUserInterfaceStyleDark
                ? [UIColor colorWithRed:0.10 green:0.30 blue:0.26 alpha:1.0]
                : [UIColor colorWithRed:0.788 green:0.925 blue:0.878 alpha:1.0];
        }];
    UIColor *blobViolet = [UIColor colorWithDynamicProvider:
        ^UIColor *(UITraitCollection *traits) {
            return traits.userInterfaceStyle == UIUserInterfaceStyleDark
                ? [UIColor colorWithRed:0.24 green:0.20 blue:0.44 alpha:1.0]
                : [UIColor colorWithRed:0.855 green:0.820 blue:0.976 alpha:1.0];
        }];
    NSArray<UIColor *> *colors = @[ blobWarm, blobPink, blobMint, blobViolet ];
    NSMutableArray<CAGradientLayer *> *blobs = [NSMutableArray array];
    for (UIColor *color in colors) {
        CAGradientLayer *layer = [CAGradientLayer layer];
        layer.type = kCAGradientLayerRadial;
        layer.colors = @[
            (id)color.CGColor,
            (id)[color colorWithAlphaComponent:0.0].CGColor,
        ];
        layer.locations = @[ @0.0, @1.0 ];
        layer.startPoint = CGPointMake(0.5, 0.5);
        layer.endPoint = CGPointMake(1.0, 1.0);
        layer.opacity = 1.0;
        [self.layer addSublayer:layer];
        [blobs addObject:layer];
    }
    _blobs = blobs;
    _resolvedColors = colors;
    [self updateBlobColors];
    return self;
}

- (void)updateBlobColors {
    [_blobs enumerateObjectsUsingBlock:^(CAGradientLayer *layer,
                                         NSUInteger index,
                                         BOOL *stop) {
        (void)stop;
        UIColor *color = self->_resolvedColors[index];
        layer.colors = @[
            (id)color.CGColor,
            (id)[color colorWithAlphaComponent:0.0].CGColor,
        ];
    }];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    if (previousTraitCollection.userInterfaceStyle !=
        self.traitCollection.userInterfaceStyle) {
        [self updateBlobColors];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGSize size = self.bounds.size;
    if (size.width <= 0 || size.height <= 0) return;
    NSArray<NSValue *> *centers = @[
        [NSValue valueWithCGPoint:CGPointMake(0.05, -0.05)],
        [NSValue valueWithCGPoint:CGPointMake(1.05, 0.18)],
        [NSValue valueWithCGPoint:CGPointMake(0.15, 1.05)],
        [NSValue valueWithCGPoint:CGPointMake(0.90, 0.95)],
    ];
    CGFloat blobWidth = size.width * 1.65;
    CGFloat blobHeight = size.height * 1.25;
    [self.blobs enumerateObjectsUsingBlock:^(CAGradientLayer *layer,
                                             NSUInteger index,
                                             BOOL *stop) {
        (void)stop;
        CGPoint center = [centers[index] CGPointValue];
        layer.frame = CGRectMake(center.x * size.width - blobWidth * 0.5,
                                 center.y * size.height - blobHeight * 0.5,
                                 blobWidth, blobHeight);
    }];
}

@end

UIColor *FMGlassPrimaryTextColor(void) {
    return UIColor.labelColor;
}

UIColor *FMGlassSecondaryTextColor(void) {
    return UIColor.secondaryLabelColor;
}

UIColor *FMGlassTertiaryTextColor(void) {
    return UIColor.tertiaryLabelColor;
}

UIColor *FMGlassHairlineColor(void) {
    return [UIColor colorWithWhite:0.0 alpha:0.10];
}

UIColor *FMGlassAccentColor(void) {
    return [UIColor colorWithRed:0.910
                           green:0.408
                            blue:0.247
                           alpha:1.0];
}

UIColor *FMGlassGreenColor(void) {
    return [UIColor colorWithRed:0.122
                           green:0.478
                            blue:0.333
                           alpha:1.0];
}

UIColor *FMGlassDangerColor(void) {
    return [UIColor colorWithRed:0.780
                           green:0.271
                            blue:0.239
                           alpha:1.0];
}

UIView *FMGlassBackgroundView(void) {
    return [[FMLiquidGradientView alloc] initWithFrame:CGRectZero];
}

UIView *FMGlassCardView(void) {
    UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
    view.backgroundColor = [UIColor colorWithDynamicProvider:
        ^UIColor *(UITraitCollection *traits) {
            return traits.userInterfaceStyle == UIUserInterfaceStyleDark
                ? [UIColor colorWithWhite:1.0 alpha:0.10]
                : [UIColor colorWithWhite:1.0 alpha:0.32];
        }];
    view.layer.cornerRadius = 26;
    view.layer.cornerCurve = kCACornerCurveContinuous;
    view.layer.borderWidth = 1.0 / UIScreen.mainScreen.scale;
    view.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.92].CGColor;
    view.layer.shadowColor = [UIColor colorWithRed:0.36
                                              green:0.26
                                               blue:0.22
                                              alpha:1.0].CGColor;
    view.layer.shadowOpacity = 0.10;
    view.layer.shadowRadius = 18;
    view.layer.shadowOffset = CGSizeMake(0, 8);
    view.clipsToBounds = YES;

    UIVisualEffectView *blur = [[UIVisualEffectView alloc]
        initWithEffect:[UIBlurEffect
            effectWithStyle:UIBlurEffectStyleSystemThinMaterial]];
    blur.translatesAutoresizingMaskIntoConstraints = NO;
    blur.userInteractionEnabled = NO;
    [view addSubview:blur];
    [NSLayoutConstraint activateConstraints:@[
        [blur.leadingAnchor constraintEqualToAnchor:view.leadingAnchor],
        [blur.trailingAnchor constraintEqualToAnchor:view.trailingAnchor],
        [blur.topAnchor constraintEqualToAnchor:view.topAnchor],
        [blur.bottomAnchor constraintEqualToAnchor:view.bottomAnchor],
    ]];
    return view;
}

static NSString *const FMFollowSystemAppearanceKey = @"FMFollowSystemAppearance";

BOOL FMFollowSystemAppearanceEnabled(void) {
    id stored = [NSUserDefaults.standardUserDefaults
        objectForKey:FMFollowSystemAppearanceKey];
    return stored == nil ? YES : [stored boolValue];
}

void FMSetFollowSystemAppearanceEnabled(BOOL enabled) {
    [NSUserDefaults.standardUserDefaults setBool:enabled
                                          forKey:FMFollowSystemAppearanceKey];
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if (![scene isKindOfClass:UIWindowScene.class]) continue;
        for (UIWindow *window in ((UIWindowScene *)scene).windows) {
            FMApplyAppearancePreferenceToWindow(window);
        }
    }
}

void FMApplyAppearancePreferenceToWindow(UIWindow *window) {
    if (window == nil) return;
    window.overrideUserInterfaceStyle = FMFollowSystemAppearanceEnabled()
        ? UIUserInterfaceStyleUnspecified : UIUserInterfaceStyleLight;
}


UIButtonConfiguration *FMGlassButtonConfiguration(NSString *title,
                                                    UIColor *tint,
                                                    BOOL filled) {
    UIButtonConfiguration *configuration = filled
        ? [UIButtonConfiguration filledButtonConfiguration]
        : [UIButtonConfiguration tintedButtonConfiguration];
    configuration.title = title;
    configuration.cornerStyle = UIButtonConfigurationCornerStyleLarge;
    configuration.baseBackgroundColor = filled
        ? [tint colorWithAlphaComponent:0.78]
        : [tint colorWithAlphaComponent:0.12];
    configuration.baseForegroundColor = filled ? UIColor.whiteColor : tint;
    return configuration;
}
