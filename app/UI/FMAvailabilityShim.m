#import <Foundation/Foundation.h>

#include <stdint.h>

// Apple's clang links compiler-rt's libclang_rt.ios.a, which defines this
// symbol for `@available` lowering. A Linux-hosted clang has no iOS builtins,
// so provide the same check from Foundation. Platform arguments are ignored
// because every target of this project is iOS.
int __isPlatformVersionAtLeast(uint32_t platform,
                               uint32_t majorVersion,
                               uint32_t minorVersion,
                               uint32_t subMinorVersion) {
    (void)platform;
    NSOperatingSystemVersion version =
        NSProcessInfo.processInfo.operatingSystemVersion;
    if (version.majorVersion != majorVersion) {
        return version.majorVersion > majorVersion;
    }
    if (version.minorVersion != minorVersion) {
        return version.minorVersion > minorVersion;
    }
    return version.patchVersion >= subMinorVersion;
}
