#import <UIKit/UIKit.h>

// Single-screen product home used by both the device app and UI test host.

@protocol FMProfileWorkspace;

NS_ASSUME_NONNULL_BEGIN

@interface FMProfileLabViewController : UIViewController

- (instancetype)initWithWorkspace:(id<FMProfileWorkspace>)workspace;

// Called by the font-library tab when the user confirms a scheme.
- (void)applyProfileFromLibrary:(NSString *)profileID;

@end

NS_ASSUME_NONNULL_END
