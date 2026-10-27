#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// Additional directories that receive the managed font mirror in addition to
// the fixed /System/Library/Fonts mapping. The list is stored below the fixed
// MarkFont engine root, never in user-writable preferences.
FOUNDATION_EXPORT NSString *const FMMountTargetsConfigurationLogicalPath;
FOUNDATION_EXPORT NSString *const FMMountTargetsErrorDomain;
FOUNDATION_EXPORT const NSUInteger FMMountTargetsMaximumCount;

// Returns the configured paths, or an empty array when no list is stored.
// Returns nil when a stored list exists but cannot be trusted.
NSArray<NSString *> * _Nullable FMMountTargetsConfiguredPaths(NSError **error);

// Replaces the stored list. An empty array removes the configuration. Paths
// are validated, deduplicated, and sorted before publication. Atomic write;
// requires effective uid 0.
BOOL FMMountTargetsWritePaths(NSArray<NSString *> *paths, NSError **error);

// An additional target must be a physical directory. Symlinks, group/other
// writable directories, "/", MarkFont-owned trees, and the system font trees
// (including their ancestors and descendants) fail. The owner may be root or
// the device user; the mirror is always mounted read-only.
BOOL FMMountTargetsValidatePath(NSString *logicalPath, NSError **error);

// Validates an additional target and prepares its jbroot source: the source is
// created by copying the current system tree when missing, and the source tree
// is made owner-writable so it can be edited. Requires effective uid 0.
BOOL FMMountTargetsPreparePath(NSString *logicalPath, NSError **error);

// Resolves the mapping source (the same logical path inside the jbroot).
NSString *FMMountTargetsSourceLogicalPath(NSString *logicalPath);

// Convenience check used by the App and the daemon. Invalid stored documents
// are treated as "not configured".
BOOL FMMountTargetsPathIsConfigured(NSString *logicalPath);

NS_ASSUME_NONNULL_END
