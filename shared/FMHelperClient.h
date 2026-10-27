#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

NSDictionary<NSString *, id> *_Nullable FMFetchStatusFromHelper(NSError **error);
NSDictionary<NSString *, id> *_Nullable FMFetchFontCatalogFromHelper(NSString *systemBuild,
                                                                      NSError **error);
NSDictionary<NSString *, id> *_Nullable FMAdoptProfileFromHelper(
    NSString *systemBuild,
    NSString *profileID,
    NSError **error);
NSDictionary<NSString *, id> *_Nullable FMStageProfileFromHelper(
    NSString *systemBuild,
    NSString *_Nullable profileID,
    NSError **error);
NSDictionary<NSString *, id> *_Nullable FMFetchUserspaceRebootPreflightFromHelper(
    NSString *systemBuild,
    NSError **error);
NSDictionary<NSString *, id> *_Nullable FMReconcileAfterRestartFromHelper(
    NSString *systemBuild,
    NSError **error);
NSDictionary<NSString *, id> *_Nullable FMRequestUserspaceRestartFromHelper(
    NSString *systemBuild,
    NSError **error);
NSDictionary<NSString *, id> *_Nullable FMRequestRespringFromHelper(
    NSString *systemBuild,
    NSError **error);
NSDictionary<NSString *, id> *_Nullable FMSetAutomaticRespringFromHelper(
    NSString *systemBuild,
    BOOL enabled,
    NSError **error);
NSDictionary<NSString *, id> *_Nullable FMFetchMountPathsFromHelper(
    NSError **error);
NSDictionary<NSString *, id> *_Nullable FMAddMountPathFromHelper(
    NSString *logicalPath,
    NSError **error);
NSDictionary<NSString *, id> *_Nullable FMRemoveMountPathFromHelper(
    NSString *logicalPath,
    NSError **error);
NSDictionary<NSString *, id> *_Nullable FMResetMountPathsFromHelper(
    NSError **error);

NS_ASSUME_NONNULL_END
