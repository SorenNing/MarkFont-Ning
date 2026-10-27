#import <UIKit/UIKit.h>

// Product settings sheet.

@protocol FMProfileWorkspace;

NS_ASSUME_NONNULL_BEGIN

@interface FMSettingsViewController : UITableViewController
- (instancetype)initWithWorkspace:(id<FMProfileWorkspace>)workspace
                  dismissalHandler:(nullable dispatch_block_t)dismissalHandler;
@end

// Mount-path management lives in its own tab now.
UIViewController *FMCreateMountPathsViewController(id<FMProfileWorkspace> workspace);

NS_ASSUME_NONNULL_END
