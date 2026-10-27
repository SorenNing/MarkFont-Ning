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

NS_ASSUME_NONNULL_END
