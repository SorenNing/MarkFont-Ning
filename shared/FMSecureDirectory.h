#import <Foundation/Foundation.h>
#import <sys/types.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString *const FMSecureDirectoryErrorDomain;

// Opens and validates an existing tree without attempting to create any
// component. This is suitable for dry-run/preflight checks.
BOOL FMValidateSecureDirectoryTree(NSString *anchorPath,
                                   NSArray<NSString *> *components,
                                   uid_t expectedUID,
                                   gid_t expectedGID,
                                   NSError **error);

// Opens every component relative to an already-physical anchor with openat(2).
// Existing components must be physical directories owned by the expected
// uid/gid and must not be group/world writable. Missing components are created
// with the supplied mode. Symbolic links are never followed.
BOOL FMEnsureSecureDirectoryTree(NSString *anchorPath,
                                 NSArray<NSString *> *components,
                                 uid_t expectedUID,
                                 gid_t expectedGID,
                                 mode_t creationMode,
                                 NSError **error);

// RootHide or the OS owns external platform anchors such as the physical
// jbroot, /var/lib, and an App container's Application Support directory.
// These variants still require the anchor to open as a physical directory
// without following a symbolic link, but deliberately do not impose an owner
// or mode policy on the anchor itself. Every component below it keeps the same
// strict uid/gid and group/world-write checks as the APIs above.
BOOL FMValidateSecureDirectoryTreeUnderPlatformAnchor(
    NSString *anchorPath,
    NSArray<NSString *> *components,
    uid_t expectedUID,
    gid_t expectedGID,
    NSError **error);

BOOL FMEnsureSecureDirectoryTreeUnderPlatformAnchor(
    NSString *anchorPath,
    NSArray<NSString *> *components,
    uid_t expectedUID,
    gid_t expectedGID,
    mode_t creationMode,
    NSError **error);

BOOL FMCreateSecureLeafDirectoryUnderPlatformAnchor(
    NSString *anchorPath,
    NSArray<NSString *> *parentComponents,
    NSString *leafComponent,
    uid_t expectedUID,
    gid_t expectedGID,
    mode_t creationMode,
    NSError **error);

// Ensures parentComponents as above, then creates a leaf that must not already
// exist. This gives baseline publication an explicit no-overwrite boundary.
BOOL FMCreateSecureLeafDirectory(NSString *anchorPath,
                                 NSArray<NSString *> *parentComponents,
                                 NSString *leafComponent,
                                 uid_t expectedUID,
                                 gid_t expectedGID,
                                 mode_t creationMode,
                                 NSError **error);

NS_ASSUME_NONNULL_END
