#import <UIKit/UIKit.h>

@protocol FMProfileWorkspace;

NS_ASSUME_NONNULL_BEGIN

// Root container with the floating liquid-glass tab bar. Tabs, in order:
// 挂载 / 字体 / 字体库 / 设置. The font tab is selected by default.
@interface FMTabBarController : UIViewController
- (instancetype)initWithWorkspace:(id<FMProfileWorkspace>)workspace;
@end

NS_ASSUME_NONNULL_END
