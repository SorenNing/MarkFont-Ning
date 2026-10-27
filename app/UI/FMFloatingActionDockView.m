#import "FMFloatingActionDockView.h"

#import <QuartzCore/QuartzCore.h>

#import "FMDesignSystem.h"

@implementation FMFloatingActionDockView

+ (Class)layerClass {
    return CAGradientLayer.class;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self == nil) return nil;
    CAGradientLayer *gradient = (CAGradientLayer *)self.layer;
    gradient.startPoint = CGPointMake(0.5, 0.0);
    gradient.endPoint = CGPointMake(0.5, 1.0);
    gradient.locations = @[ @0.0, @0.34, @0.68 ];
    [self updateGradientColors];
    if (@available(iOS 17.0, *)) {
        __weak typeof(self) weakSelf = self;
        Class styleTrait = NSClassFromString(@"UITraitUserInterfaceStyle");
        if (styleTrait != Nil) {
            [self registerForTraitChanges:@[ styleTrait ]
                              withHandler:^(__unused id<UITraitEnvironment> environment,
                                        __unused UITraitCollection *previousTraitCollection) {
                [weakSelf updateGradientColors];
            }];
        }
    }
    return self;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
#pragma clang diagnostic ignored "-Wdeprecated-implementations"
- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    if (@available(iOS 17.0, *)) return;
    if (previousTraitCollection == nil ||
        previousTraitCollection.userInterfaceStyle !=
            self.traitCollection.userInterfaceStyle) {
        [self updateGradientColors];
    }
}
#pragma clang diagnostic pop

- (void)updateGradientColors {
    // Fade into the shared glass canvas instead of painting an opaque dock.
    UIColor *canvas = [UIColor colorWithRed:0.980
                                      green:0.969
                                       blue:0.953
                                      alpha:1.0];
    ((CAGradientLayer *)self.layer).colors = @[
        (id)[canvas colorWithAlphaComponent:0.0].CGColor,
        (id)[canvas colorWithAlphaComponent:0.80].CGColor,
        (id)[canvas colorWithAlphaComponent:0.94].CGColor,
    ];
    ((CAGradientLayer *)self.layer).locations = @[ @0.0, @0.30, @0.62 ];
}

@end
