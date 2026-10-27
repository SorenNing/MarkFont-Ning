#import <UIKit/UIKit.h>

// The project is built against an iOS 17+ SDK upstream. When it is built with
// an older SDK (for example iPhoneOS16.5.sdk), UIKit does not declare the
// iOS 17 trait-registration API. All call sites are guarded by
// `@available(iOS 17.0, *)`, so a declaration is all that is missing; the
// selector and the trait class are resolved at runtime from UIKit.
#if __IPHONE_OS_VERSION_MAX_ALLOWED < 170000
@interface UIView (FMTraitRegistrationCompatibility)
- (void)registerForTraitChanges:(NSArray *)traits
                    withHandler:(void (^)(id<UITraitEnvironment> environment,
                                          UITraitCollection *previousTraitCollection))handler;
@end

@interface UIViewController (FMTraitRegistrationCompatibility)
- (void)registerForTraitChanges:(NSArray *)traits
                    withHandler:(void (^)(id<UITraitEnvironment> environment,
                                          UITraitCollection *previousTraitCollection))handler;
@end
#endif
