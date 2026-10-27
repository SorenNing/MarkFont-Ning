#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

// Glass palette shared by the Settings flow.
UIColor *FMGlassPrimaryTextColor(void);
UIColor *FMGlassSecondaryTextColor(void);
UIColor *FMGlassTertiaryTextColor(void);
UIColor *FMGlassHairlineColor(void);
UIColor *FMGlassAccentColor(void);
UIColor *FMGlassGreenColor(void);
UIColor *FMGlassDangerColor(void);

// Full-bleed gradient mesh used behind the settings pages.
UIView *FMGlassBackgroundView(void);

// Translucent frosted card with a hairline highlight border.
UIView *FMGlassCardView(void);
UIButtonConfiguration *FMGlassButtonConfiguration(NSString *title,
                                                    UIColor *tint,
                                                    BOOL filled);

// Appearance preference. When enabled (default) the app follows the system
// light/dark setting; otherwise it stays in the light appearance.
BOOL FMFollowSystemAppearanceEnabled(void);
void FMSetFollowSystemAppearanceEnabled(BOOL enabled);
void FMApplyAppearancePreferenceToWindow(UIWindow *window);

NS_ASSUME_NONNULL_END
