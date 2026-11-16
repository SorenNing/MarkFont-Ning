include ../Config.mk
include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = FontManager

FontManager_FILES = main.m FMAppDelegate.m FMDeviceProfileWorkspace.m \
    UI/FMFloatingActionDockView.m UI/FMProfileLabViewController.m \
    UI/FMFontLibraryViewController.m UI/FMMixFontViewController.m \
    UI/FMSettingsViewController.m UI/FMCompatibilityViewController.m UI/FMGlassStyle.m UI/FMTabBarController.m UI/FMAvailabilityShim.m \
    ../shared/FMStatusContract.m ../shared/FMDataModel.m \
    ../shared/FMFontCatalog.m ../shared/FMFontPackageContentRefinement.m \
    ../shared/FMFontPackageMatcher.m \
    ../shared/FMFontPackageAnalyzer.m ../shared/FMFontPackageImportSession.m \
    ../shared/FMFontProfileStore.m ../shared/FMSystemFontLayout.m \
    ../shared/FMFileStore.m ../shared/FMHelperClient.m \
    ../shared/FMFontSlotCatalog.m ../shared/FMMixFontProfile.m \
    ../shared/FMMountTarget.m
# Compile upstream and the ObjC-visible bridge as one module (FontManager).
# The original tab bar is replaced only in build output by the UI generator.
MARKFONT_THESEUS_ROOT := ../vendor/Theseus/Sources/Theseus
# Swift inputs are identical across recursive architecture passes.
MARKFONT_THESEUS_GENERATED := ../.theos/markfont-theseus/$(THEOS_PACKAGE_SCHEME)/generated
MARKFONT_THESEUS_TABBAR := $(MARKFONT_THESEUS_GENERATED)/TheseusTabBar.swift
MARKFONT_THESEUS_SHIM := $(MARKFONT_THESEUS_GENERATED)/TheseusBundle.swift
MARKFONT_THESEUS_BUNDLE := ../.theos/markfont-theseus/$(THEOS_PACKAGE_SCHEME)/$(or $(THEOS_CURRENT_ARCH),universal)/Resources/Theseus_Theseus.bundle
MARKFONT_THESEUS_SWIFT := $(shell find $(MARKFONT_THESEUS_ROOT) -type f -name '*.swift' ! -path '*/Components/TheseusTabBar.swift' ! -path '*/Core/TheseusView.swift' ! -path '*/Rendering/TheseusRenderer.swift' ! -path '*/Rendering/CaptureCompensation.swift' 2>/dev/null | LC_ALL=C sort)
MARKFONT_THESEUS_SWIFT += $(addprefix $(MARKFONT_THESEUS_GENERATED)/,TheseusView.swift TheseusRenderer.swift CaptureCompensation.swift)
MARKFONT_THESEUS_METAL := $(shell find $(MARKFONT_THESEUS_ROOT)/Shaders -type f -name '*.metal' 2>/dev/null | LC_ALL=C sort)
MARKFONT_THESEUS_SHADER_INPUTS := $(shell find $(MARKFONT_THESEUS_ROOT)/Shaders -type f 2>/dev/null | LC_ALL=C sort)
FontManager_FILES += $(MARKFONT_THESEUS_SWIFT) $(MARKFONT_THESEUS_TABBAR) \
    $(MARKFONT_THESEUS_SHIM) UI/FMTheseusTabBar.swift
FontManager_SWIFT_VERSION = 5
# ObjC uses its explicit @interface; no import of FontManager-Swift.h is needed.
# Theos may still emit that header as part of its normal mixed-language rule.
# Swift objects carry autolink entries. Supply both dynamic runtime and static
# compatibility archive paths when the final link is driven by clang (Theos).
ifneq ($(THEOS_PLATFORM_NAME),iphone)
MARKFONT_SWIFT_LIB := $(shell xcrun --sdk iphoneos --find swiftc 2>/dev/null | sed 's@/bin/swiftc$$@/lib@')
ifneq ($(MARKFONT_SWIFT_LIB),)
FontManager_LDFLAGS += -L$(MARKFONT_SWIFT_LIB)/swift/iphoneos -L$(MARKFONT_SWIFT_LIB)/swift_static/iphoneos
endif
endif
FontManager_LDFLAGS += -Wl,-rpath,/usr/lib/swift
FontManager_FRAMEWORKS = UIKit QuartzCore CoreText UniformTypeIdentifiers CoreGraphics Metal MetalKit IOSurface CoreVideo Accelerate
FontManager_LIBRARIES = $(MARKFONT_PATH_LIBRARIES)
FontManager_CFLAGS = -fobjc-arc -Wall -Wextra $(MARKFONT_PATH_CFLAGS) -I../shared -IUI
FontManager_CODESIGN_FLAGS = -Sentitlements.plist -Icom.hmmzzz.fontmanager
FontManager_RESOURCE_DIRS = Resources

# Theos enumerates Swift inputs and checks __USER_FILES in its own independent
# before-FontManager-all:: recipe. A later double-colon prerequisite cannot
# order generation before that check. Prepare only lightweight Swift sources
# synchronously, before application.mk, for direct and recursive developer make.
# $(shell) does not propagate failures, so capture and check the exit status.
# A clean-only invocation must remain usable even with missing vendor inputs.
ifneq ($(if $(MAKECMDGOALS),$(filter-out clean internal-clean after-clean,$(MAKECMDGOALS)),all),)
MARKFONT_THESEUS_PREPARE_STATUS := $(shell python3 UI/prepare_theseus_tabbar.py "$(MARKFONT_THESEUS_ROOT)/Components/TheseusTabBar.swift" "$(MARKFONT_THESEUS_TABBAR)" >&2 && bash ../scripts/prepare-theseus-resources shim "$(MARKFONT_THESEUS_SHIM)" >&2; echo $$?)
ifneq ($(MARKFONT_THESEUS_PREPARE_STATUS),0)
$(error Theseus Swift source preparation failed (status $(MARKFONT_THESEUS_PREPARE_STATUS)))
endif
endif

include $(THEOS_MAKE_PATH)/application.mk

$(MARKFONT_THESEUS_BUNDLE)/default.metallib: $(MARKFONT_THESEUS_SHADER_INPUTS) ../scripts/prepare-theseus-resources
	bash ../scripts/prepare-theseus-resources metal "$(MARKFONT_THESEUS_ROOT)/Shaders" "$(MARKFONT_THESEUS_BUNDLE)" "$(SYSROOT)" "$(_THEOS_TARGET_OS_DEPLOYMENT_VERSION)"

.PHONY: markfont-theseus-inputs
markfont-theseus-inputs:
	@test -n "$(MARKFONT_THESEUS_SWIFT)" || { echo 'Missing vendor/Theseus Swift sources' >&2; exit 1; }
	@test -n "$(MARKFONT_THESEUS_METAL)" || { echo 'Missing vendor/Theseus Metal shaders' >&2; exit 1; }
	@test -f UI/FMTheseusTabBar.swift || { echo 'Missing UI/FMTheseusTabBar.swift bridge' >&2; exit 1; }

before-FontManager-all:: markfont-theseus-inputs

# Keep copying in our own double-colon recipe: adding prerequisites to Theos's
# separate resource recipe would not order that recipe under parallel make.
ifneq ($(THEOS_CURRENT_INSTANCE),)
.PHONY: markfont-theseus-resources
markfont-theseus-resources: $(MARKFONT_THESEUS_BUNDLE)/default.metallib
	@mkdir -p "$(THEOS_SHARED_BUNDLE_RESOURCE_PATH)"
	@rm -rf "$(THEOS_SHARED_BUNDLE_RESOURCE_PATH)/Theseus_Theseus.bundle"
	cp -R "$(MARKFONT_THESEUS_BUNDLE)" "$(THEOS_SHARED_BUNDLE_RESOURCE_PATH)/"
	@mkdir -p "$(THEOS_SHARED_BUNDLE_RESOURCE_PATH)/Licenses/Theseus"
	cp ../vendor/Theseus/LICENSE ../vendor/Theseus/NOTICE "$(THEOS_SHARED_BUNDLE_RESOURCE_PATH)/Licenses/Theseus/"
shared-instance-bundle-all:: markfont-theseus-resources
endif

after-clean::
	rm -rf "../.theos/markfont-theseus/$(THEOS_PACKAGE_SCHEME)"
