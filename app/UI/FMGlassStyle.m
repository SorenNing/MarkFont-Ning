#import "FMGlassStyle.h"

@interface FMLiquidGradientView : UIView
@property(nonatomic, copy) NSArray<CAGradientLayer *> *blobs;
@end

@implementation FMLiquidGradientView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self == nil) return nil;
    self.backgroundColor = [UIColor colorWithRed:0.980
                                           green:0.969
                                            blue:0.953
                                           alpha:1.0];
    NSArray<UIColor *> *colors = @[
        [UIColor colorWithRed:1.000 green:0.941 blue:0.902 alpha:1.0],
        [UIColor colorWithRed:1.000 green:0.929 blue:0.953 alpha:1.0],
        [UIColor colorWithRed:0.918 green:0.976 blue:0.957 alpha:1.0],
        [UIColor colorWithRed:0.949 green:0.933 blue:1.000 alpha:1.0],
    ];
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
        layer.opacity = 0.9;
        [self.layer addSublayer:layer];
        [blobs addObject:layer];
    }
    _blobs = blobs;
    return self;
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
    view.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.55];
    view.layer.cornerRadius = 26;
    view.layer.cornerCurve = kCACornerCurveContinuous;
    view.layer.borderWidth = 1.0 / UIScreen.mainScreen.scale;
    view.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.92].CGColor;
    view.clipsToBounds = YES;

    UIVisualEffectView *blur = [[UIVisualEffectView alloc]
        initWithEffect:[UIBlurEffect
            effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterialLight]];
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
