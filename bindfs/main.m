#import <Foundation/Foundation.h>

#import <dlfcn.h>
#import <errno.h>
#import <roothide.h>
#import <stdint.h>
#import <stdio.h>
#import <string.h>
#import <sys/mount.h>
#import <sys/stat.h>
#import <unistd.h>

#import "../shared/FMMountBackendProtocol.h"
#import "../shared/FMMountTarget.h"
#import "../shared/FMSystemFontLayout.h"

typedef int (*FMRootStealUcredFunction)(uint64_t ucredToSteal,
                                        uint64_t *originalUcred);

static NSString *const FMLibJailbreakLogicalPath =
    @"/basebin/libjailbreak.dylib";
static NSString *const FMMirrorRootLogicalPath = @"/bindfs";
static NSString *const FMMirrorSystemLogicalPath = @"/bindfs/System";
static NSString *const FMMirrorLibraryLogicalPath = @"/bindfs/System/Library";
static NSString *const FMFontsMirrorLogicalPath = @"/bindfs/System/Library/Fonts";
static NSString *const FMPrivateFrameworksMirrorLogicalPath =
    @"/bindfs/System/Library/PrivateFrameworks";
static NSString *const FMFontServicesMirrorLogicalPath =
    @"/bindfs/System/Library/PrivateFrameworks/FontServices.framework";
static NSString *const FMFontServicesCorePrivateMirrorLogicalPath =
    @"/bindfs/System/Library/PrivateFrameworks/FontServices.framework/CorePrivate";
static NSString *const FMSystemFontsPath = @"/System/Library/Fonts";
static NSString *const FMFontServicesCorePrivatePath =
    @"/System/Library/PrivateFrameworks/FontServices.framework/CorePrivate";

static int FMExitStatusForErrno(int errorNumber) {
    if (errorNumber > 0 &&
        errorNumber <= FMMountBackendProcessMaximumEncodedErrno) {
        return FMMountBackendProcessExitErrnoBase + errorNumber;
    }
    return FMMountBackendProcessExitUnknownSyscall;
}

static BOOL FMRootOwnedSecureRegularFile(NSString *path) {
    struct stat info = {0};
    return path.length > 0 &&
        lstat(path.fileSystemRepresentation, &info) == 0 &&
        S_ISREG(info.st_mode) && info.st_uid == 0 &&
        (info.st_mode & (S_IWGRP | S_IWOTH)) == 0;
}

static BOOL FMRootOwnedSecureDirectory(NSString *path) {
    struct stat info = {0};
    return path.length > 0 &&
        lstat(path.fileSystemRepresentation, &info) == 0 &&
        S_ISDIR(info.st_mode) && info.st_uid == 0 && info.st_gid == 0 &&
        (info.st_mode & (S_IWGRP | S_IWOTH)) == 0;
}

static BOOL FMPhysicalDirectory(NSString *path) {
    struct stat info = {0};
    return path.length > 0 &&
        lstat(path.fileSystemRepresentation, &info) == 0 &&
        S_ISDIR(info.st_mode) && !S_ISLNK(info.st_mode);
}

static BOOL FMValidateFixedMapping(NSDictionary<NSString *, NSString *> *mapping,
                                   NSString **mirrorPath) {
    BOOL supplemental = [mapping[@"kind"] isEqual:@"fontServicesCorePrivate"];
    NSArray<NSString *> *logicalPaths = supplemental
        ? @[
            FMMirrorRootLogicalPath,
            FMMirrorSystemLogicalPath,
            FMMirrorLibraryLogicalPath,
            FMPrivateFrameworksMirrorLogicalPath,
            FMFontServicesMirrorLogicalPath,
            FMFontServicesCorePrivateMirrorLogicalPath,
        ]
        : @[
            FMMirrorRootLogicalPath,
            FMMirrorSystemLogicalPath,
            FMMirrorLibraryLogicalPath,
            FMFontsMirrorLogicalPath,
        ];
    for (NSString *logicalPath in logicalPaths) {
        if (!FMRootOwnedSecureDirectory(jbroot(logicalPath))) {
            return NO;
        }
    }

    struct stat targetInfo = {0};
    NSString *targetPath = mapping[@"target"];
    if (lstat(targetPath.fileSystemRepresentation, &targetInfo) != 0 ||
        !S_ISDIR(targetInfo.st_mode)) {
        return NO;
    }
    if (mirrorPath != NULL) {
        *mirrorPath = jbroot(mapping[@"mirror"]);
    }
    return YES;
}

static BOOL FMMappingIsExact(NSString *targetPath,
                             NSString *mirrorPath,
                             BOOL *dedicatedMappingPresent,
                             BOOL *inspectionAvailable) {
    struct statfs mapping = {0};
    if (statfs(targetPath.fileSystemRepresentation, &mapping) != 0) {
        if (inspectionAvailable != NULL) {
            *inspectionAvailable = NO;
        }
        if (dedicatedMappingPresent != NULL) {
            *dedicatedMappingPresent = NO;
        }
        return NO;
    }
    if (inspectionAvailable != NULL) {
        *inspectionAvailable = YES;
    }

    NSString *target = [NSString stringWithUTF8String:mapping.f_mntonname];
    BOOL dedicated = [target isEqualToString:targetPath];
    if (dedicatedMappingPresent != NULL) {
        *dedicatedMappingPresent = dedicated;
    }
    if (!dedicated) {
        return NO;
    }

    NSString *filesystemType =
        [NSString stringWithUTF8String:mapping.f_fstypename];
    NSString *source = [NSString stringWithUTF8String:mapping.f_mntfromname];
    return filesystemType != nil && source != nil &&
        [filesystemType caseInsensitiveCompare:@"bindfs"] == NSOrderedSame &&
        [source.stringByResolvingSymlinksInPath
            isEqualToString:mirrorPath.stringByResolvingSymlinksInPath] &&
        (mapping.f_flags & MNT_RDONLY) != 0;
}

static BOOL FMMappingIsActive(NSString *targetPath,
                              NSString *mirrorPath,
                              BOOL *dedicatedMappingPresent,
                              BOOL *inspectionAvailable);

static NSArray<NSDictionary<NSString *, NSString *> *> *FMFixedMappings(void) {
    FMSystemFontLayout layout = FMCurrentSystemFontLayout(nil, nil);
    if (layout == FMSystemFontLayoutUnsupported) return nil;

    NSMutableArray<NSDictionary<NSString *, NSString *> *> *mappings =
        [NSMutableArray arrayWithObject:@{
            @"kind" : @"systemFonts",
            @"target" : FMSystemFontsPath,
            @"mirror" : FMFontsMirrorLogicalPath,
        }];
    if (layout == FMSystemFontLayoutPrimaryFonts) return mappings;

    struct stat supplementalInfo = {0};
    errno = 0;
    NSString *supplementalMirror =
        jbroot(FMFontServicesCorePrivateMirrorLogicalPath);
    if (lstat(supplementalMirror.fileSystemRepresentation,
              &supplementalInfo) == 0) {
        [mappings addObject:@{
            @"kind" : @"fontServicesCorePrivate",
            @"target" : FMFontServicesCorePrivatePath,
            @"mirror" : FMFontServicesCorePrivateMirrorLogicalPath,
        }];
    } else if (errno != ENOENT) {
        return nil;
    }
    return mappings;
}

// Additional user-configured targets always receive the full managed Fonts
// mirror. They are strictly secondary: an unusable entry is skipped so the
// fixed system mapping can never be blocked by an optional path.
static NSArray<NSDictionary<NSString *, id> *> *FMExtraMappingFacts(void) {
    NSError *configurationError = nil;
    NSArray<NSString *> *paths =
        FMMountTargetsConfiguredPaths(&configurationError);
    if (paths == nil || paths.count == 0) return @[];

    NSMutableArray<NSDictionary<NSString *, id> *> *facts =
        [NSMutableArray arrayWithCapacity:paths.count];
    for (NSString *path in paths) {
        if (!FMMountTargetsValidatePath(path, NULL)) continue;
        NSString *mirrorPath = jbroot(path);
        if (!FMPhysicalDirectory(mirrorPath)) continue;
        BOOL dedicated = NO;
        BOOL inspectionAvailable = NO;
        BOOL exact = FMMappingIsActive(path, mirrorPath, &dedicated,
                                      &inspectionAvailable);
        // A foreign dedicated mapping already owns this path. Never stack our
        // mirror over another package's mount.
        if (!inspectionAvailable || (dedicated && !exact)) continue;
        [facts addObject:@{
            @"target" : path,
            @"mirrorPath" : mirrorPath,
            @"exact" : @(exact),
        }];
    }
    return facts;
}

static int FMPerformMappingSyscall(BOOL unmountOperation,
                                   NSString *targetPath,
                                   NSString *mirrorPath,
                                   BOOL readOnly) {
    return unmountOperation
        ? unmount(targetPath.fileSystemRepresentation, MNT_FORCE)
        : mount("bindfs", targetPath.fileSystemRepresentation,
                readOnly ? MNT_RDONLY : 0,
                (void *)mirrorPath.fileSystemRepresentation);
}

// Additional mappings are intentionally read-write: the backing directory
// lives in the jbroot, so edits made through the mapped path only change that
// copy and never the sealed system volume.
static BOOL FMMappingIsActive(NSString *targetPath,
                              NSString *mirrorPath,
                              BOOL *dedicatedMappingPresent,
                              BOOL *inspectionAvailable) {
    struct statfs mapping = {0};
    if (statfs(targetPath.fileSystemRepresentation, &mapping) != 0) {
        if (inspectionAvailable != NULL) *inspectionAvailable = NO;
        if (dedicatedMappingPresent != NULL) *dedicatedMappingPresent = NO;
        return NO;
    }
    if (inspectionAvailable != NULL) *inspectionAvailable = YES;
    NSString *target = [NSString stringWithUTF8String:mapping.f_mntonname];
    BOOL dedicated = [target isEqualToString:targetPath];
    if (dedicatedMappingPresent != NULL) *dedicatedMappingPresent = dedicated;
    if (!dedicated) return NO;
    NSString *filesystemType =
        [NSString stringWithUTF8String:mapping.f_fstypename];
    NSString *source = [NSString stringWithUTF8String:mapping.f_mntfromname];
    return filesystemType != nil && source != nil &&
        [filesystemType caseInsensitiveCompare:@"bindfs"] == NSOrderedSame &&
        [source.stringByResolvingSymlinksInPath
            isEqualToString:mirrorPath.stringByResolvingSymlinksInPath];
}

static void *FMLoadCredentialFunction(FMRootStealUcredFunction *function) {
    NSString *libraryPath = jbroot(FMLibJailbreakLogicalPath);
    if (!FMRootOwnedSecureRegularFile(libraryPath)) {
        return NULL;
    }

    void *handle = dlopen(libraryPath.fileSystemRepresentation,
                          RTLD_NOW | RTLD_LOCAL);
    if (handle == NULL) {
        return NULL;
    }

    void *symbol = dlsym(handle, "jbclient_root_steal_ucred");
    if (symbol == NULL) {
        dlclose(handle);
        return NULL;
    }
    *function = (FMRootStealUcredFunction)symbol;
    return handle;
}

static int FMRunMountOperation(BOOL forceUnmount,
                               FMRootStealUcredFunction credentialFunction) {
    NSArray<NSDictionary<NSString *, NSString *> *> *fixedMappings =
        FMFixedMappings();
    if (fixedMappings.count == 0) return FMMountBackendProcessExitUnsafeState;

    NSMutableArray<NSDictionary<NSString *, id> *> *fixedFacts =
        [NSMutableArray arrayWithCapacity:fixedMappings.count];
    NSUInteger exactFixedCount = 0;
    for (NSDictionary<NSString *, NSString *> *mapping in fixedMappings) {
        NSString *mirrorPath = nil;
        if (!FMValidateFixedMapping(mapping, &mirrorPath)) {
            return FMMountBackendProcessExitUnsafeState;
        }
        BOOL dedicated = NO;
        BOOL inspectionAvailable = NO;
        BOOL exact = FMMappingIsExact(
            mapping[@"target"], mirrorPath, &dedicated, &inspectionAvailable);
        if (!inspectionAvailable || (dedicated && !exact)) {
            return FMMountBackendProcessExitUnsafeState;
        }
        if (exact) exactFixedCount++;
        [fixedFacts addObject:@{
            @"target" : mapping[@"target"],
            @"mirrorPath" : mirrorPath,
            @"exact" : @(exact),
        }];
    }

    NSArray<NSDictionary<NSString *, id> *> *extraFacts =
        FMExtraMappingFacts();
    NSUInteger exactExtraCount = 0;
    BOOL pendingExtraMount = NO;
    for (NSDictionary<NSString *, id> *fact in extraFacts) {
        if ([fact[@"exact"] boolValue]) {
            exactExtraCount++;
        } else {
            pendingExtraMount = YES;
        }
    }

    if (forceUnmount) {
        if (exactFixedCount + exactExtraCount == 0) {
            return FMMountBackendProcessExitNotMounted;
        }
    } else if (exactFixedCount == fixedMappings.count &&
               !pendingExtraMount) {
        return 0;
    }

    uint64_t originalCredential = 0;
    int borrowResult = credentialFunction(0, &originalCredential);
    if (borrowResult != 0 || originalCredential == 0) {
        return FMMountBackendProcessExitCredentialBorrow;
    }

    __block int operationError = 0;
    NSMutableArray<NSDictionary<NSString *, id> *> *mountedNow =
        [NSMutableArray array];
    NSEnumerationOptions options = forceUnmount
        ? NSEnumerationReverse : 0;
    [fixedFacts enumerateObjectsWithOptions:options
                                 usingBlock:^(NSDictionary<NSString *, id> *fact,
                                              NSUInteger index,
                                              BOOL *stop) {
        (void)index;
        if (forceUnmount != [fact[@"exact"] boolValue]) return;
        errno = 0;
        int result = FMPerformMappingSyscall(
            forceUnmount, fact[@"target"], fact[@"mirrorPath"], YES);
        if (result != 0) {
            if (operationError == 0) operationError = errno ?: EIO;
            if (!forceUnmount) *stop = YES;
            return;
        }
        if (!forceUnmount) [mountedNow addObject:fact];
    }];

    if (!forceUnmount && operationError != 0) {
        for (NSDictionary<NSString *, id> *fact in mountedNow.reverseObjectEnumerator) {
            errno = 0;
            FMPerformMappingSyscall(YES, fact[@"target"], fact[@"mirrorPath"],
                                    YES);
        }
    } else {
        // Extra targets are best effort in both directions. Their failure must
        // not roll back the verified system mapping.
        for (NSDictionary<NSString *, id> *fact in extraFacts) {
            if (forceUnmount != [fact[@"exact"] boolValue]) continue;
            errno = 0;
            FMPerformMappingSyscall(
                forceUnmount, fact[@"target"], fact[@"mirrorPath"], NO);
        }
    }

    int restoreResult = credentialFunction(originalCredential, NULL);
    if (restoreResult != 0) {
        return FMMountBackendProcessExitCredentialRestore;
    }
    if (operationError != 0) {
        errno = operationError;
        return FMExitStatusForErrno(operationError);
    }
    return 0;
}

static int FMRunAttachExtra(NSString *path,
                            FMRootStealUcredFunction credentialFunction) {
    if (!FMMountTargetsValidatePath(path, NULL)) {
        return FMMountBackendProcessExitUnsafeState;
    }
    NSString *mirrorPath = jbroot(path);
    if (!FMPhysicalDirectory(mirrorPath)) {
        return FMMountBackendProcessExitUnsafeState;
    }
    BOOL dedicated = NO;
    BOOL inspectionAvailable = NO;
    BOOL active = FMMappingIsActive(path, mirrorPath, &dedicated,
                                    &inspectionAvailable);
    if (!inspectionAvailable || (dedicated && !active)) {
        return FMMountBackendProcessExitUnsafeState;
    }

    struct statfs current = {0};
    BOOL readOnly = active &&
        statfs(path.fileSystemRepresentation, &current) == 0 &&
        (current.f_flags & MNT_RDONLY) != 0;
    if (active && !readOnly) return 0;

    uint64_t originalCredential = 0;
    int borrowResult = credentialFunction(0, &originalCredential);
    if (borrowResult != 0 || originalCredential == 0) {
        return FMMountBackendProcessExitCredentialBorrow;
    }
    if (active) {
        // Migrate an older read-only mapping to the writable form.
        errno = 0;
        int detachResult = FMPerformMappingSyscall(YES, path, mirrorPath, NO);
        if (detachResult != 0) {
            int savedError = errno ?: EIO;
            credentialFunction(originalCredential, NULL);
            errno = savedError;
            return FMExitStatusForErrno(savedError);
        }
    }
    errno = 0;
    int result = FMPerformMappingSyscall(NO, path, mirrorPath, NO);
    int savedError = errno;
    int restoreResult = credentialFunction(originalCredential, NULL);
    if (restoreResult != 0) {
        return FMMountBackendProcessExitCredentialRestore;
    }
    if (result != 0) {
        errno = savedError ?: EIO;
        return FMExitStatusForErrno(savedError ?: EIO);
    }
    return 0;
}

static int FMRunDetachExtra(NSString *path,
                            FMRootStealUcredFunction credentialFunction) {
    if (!FMMountTargetsValidatePath(path, NULL)) {
        return FMMountBackendProcessExitUnsafeState;
    }
    NSString *mirrorPath = jbroot(path);
    struct statfs mapping = {0};
    if (statfs(path.fileSystemRepresentation, &mapping) != 0) {
        return FMExitStatusForErrno(errno);
    }
    NSString *target = [NSString stringWithUTF8String:mapping.f_mntonname];
    if (![target isEqualToString:path]) {
        // Nothing of ours is mounted exactly here.
        return 0;
    }
    NSString *filesystemType =
        [NSString stringWithUTF8String:mapping.f_fstypename];
    NSString *source = [NSString stringWithUTF8String:mapping.f_mntfromname];
    BOOL ours = filesystemType != nil && source != nil &&
        [filesystemType caseInsensitiveCompare:@"bindfs"] == NSOrderedSame &&
        [source.stringByResolvingSymlinksInPath
            isEqualToString:mirrorPath.stringByResolvingSymlinksInPath];
    if (!ours) return FMMountBackendProcessExitUnsafeState;

    uint64_t originalCredential = 0;
    int borrowResult = credentialFunction(0, &originalCredential);
    if (borrowResult != 0 || originalCredential == 0) {
        return FMMountBackendProcessExitCredentialBorrow;
    }
    errno = 0;
    int result = FMPerformMappingSyscall(YES, path, mirrorPath, NO);
    int savedError = errno;
    int restoreResult = credentialFunction(originalCredential, NULL);
    if (restoreResult != 0) {
        return FMMountBackendProcessExitCredentialRestore;
    }
    if (result != 0) {
        errno = savedError ?: EIO;
        return FMExitStatusForErrno(savedError ?: EIO);
    }
    return 0;
}

static int FMRunDetachAllExtras(FMRootStealUcredFunction credentialFunction) {
    NSArray<NSString *> *paths = FMMountTargetsConfiguredPaths(NULL);
    for (NSString *path in paths) {
        FMRunDetachExtra(path, credentialFunction);
    }
    return 0;
}

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        if (argc == 2 && strcmp(argv[1], "--version") == 0) {
            fputs("markfont-bindfs 2\n", stdout);
            return 0;
        }
        BOOL attachCommand = argc == 3 &&
            strcmp(argv[1], "attach-extra-fonts") == 0;
        BOOL detachCommand = argc == 3 &&
            strcmp(argv[1], "detach-extra-fonts") == 0;
        BOOL baseCommand = argc == 2 &&
            (strcmp(argv[1], "probe") == 0 ||
             strcmp(argv[1], "mount-fonts") == 0 ||
             strcmp(argv[1], "force-unmount-fonts") == 0 ||
             strcmp(argv[1], "detach-all-extra-fonts") == 0);
        if (!attachCommand && !detachCommand && !baseCommand) {
            return FMMountBackendProcessExitUsage;
        }
        if (geteuid() != 0) {
            return FMMountBackendProcessExitPermission;
        }

        FMRootStealUcredFunction credentialFunction = NULL;
        void *libraryHandle = FMLoadCredentialFunction(&credentialFunction);
        if (libraryHandle == NULL || credentialFunction == NULL) {
            return FMMountBackendProcessExitUnavailable;
        }

        int result = 0;
        if (attachCommand) {
            result = FMRunAttachExtra(
                [NSString stringWithUTF8String:argv[2]], credentialFunction);
        } else if (detachCommand) {
            result = FMRunDetachExtra(
                [NSString stringWithUTF8String:argv[2]], credentialFunction);
        } else if (strcmp(argv[1], "detach-all-extra-fonts") == 0) {
            result = FMRunDetachAllExtras(credentialFunction);
        } else if (strcmp(argv[1], "probe") != 0) {
            result = FMRunMountOperation(
                strcmp(argv[1], "force-unmount-fonts") == 0,
                credentialFunction);
        }
        dlclose(libraryHandle);
        return result;
    }
}
