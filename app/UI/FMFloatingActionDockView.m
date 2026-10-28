#import "FMFloatingActionDockView.h"

#import <QuartzCore/QuartzCore.h>

#import "FMDesignSystem.h"

@implementation FMFloatingActionDockView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self == nil) return nil;
    // Transparent container: the apply button itself carries the glass look, so
    // no opaque canvas band appears above the tab bar.
    self.backgroundColor = UIColor.clearColor;
    return self;
}

@end
