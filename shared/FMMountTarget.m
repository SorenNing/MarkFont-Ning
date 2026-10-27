#import "FMMountTarget.h"

#import <copyfile.h>
#import <errno.h>
#import <roothide.h>
#import <string.h>
#import <sys/stat.h>
#import <unistd.h>

NSString *const FMMountTargetsConfigurationLogicalPath =
    @"/var/lib/fontmanager/custom-mount-paths.json";
NSString *const FMMountTargetsErrorDomain =
    @"com.hmmzzz.fontmanager.mount-targets";
const NSUInteger FMMountTargetsMaximumCount = 16;

static NSString *const FMMountTargetsSystemFontsPath = @"/System/Library/Fonts";
static NSString *const FMMountTargetsSupplementalPath =
    @"/System/Library/PrivateFrameworks/FontServices.framework/CorePrivate";
static NSString *const FMMountTargetsFontServicesRoot =
    @"/System/Library/PrivateFrameworks/FontServices.framework";
static NSString *const FMMountTargetsStorageMirrorRoot = @"/bindfs";
static NSString *const FMMountTargetsEngineRoot = @"/var/lib/fontmanager";
static NSString *const FMMountTargetsPreferenceRoot =
    @"/var/mobile/Library/Preferences";

static BOOL FMMountTargetsFail(NSError **error,
                               NSInteger code,
                               NSString *description,
                               int errorNumber) {
    if (error != NULL) {
        NSMutableDictionary *userInfo =
            [NSMutableDictionary dictionaryWithObject:description
                                               forKey:NSLocalizedDescriptionKey];
        if (errorNumber != 0) {
            userInfo[NSUnderlyingErrorKey] =
                [NSError errorWithDomain:NSPOSIXErrorDomain
                                    code:errorNumber
                                userInfo:nil];
        }
        *error = [NSError errorWithDomain:FMMountTargetsErrorDomain
                                     code:code
                                 userInfo:userInfo];
    }
    return NO;
}

static BOOL FMMountTargetsPathIsInside(NSString *path, NSString *root) {
    if ([path isEqual:root]) return YES;
    return [path hasPrefix:[root stringByAppendingString:@"/"]];
}

static BOOL FMMountTargetsPathsOverlap(NSString *first, NSString *second) {
    return FMMountTargetsPathIsInside(first, second) ||
        FMMountTargetsPathIsInside(second, first);
}

static BOOL FMMountTargetsHasUnsafeComponents(NSString *path) {
    for (NSString *component in path.pathComponents) {
        if ([component isEqual:@"."] || [component isEqual:@".."]) {
            return YES;
        }
    }
    return NO;
}

static BOOL FMMountTargetsValidateStructure(NSString *logicalPath,
                                             NSError **error) {
    if (![logicalPath isKindOfClass:NSString.class] || logicalPath.length == 0) {
        return FMMountTargetsFail(error, 1,
                                  @"A mount path is required.", 0);
    }
    if (logicalPath.UTF8String == NULL ||
        strlen(logicalPath.UTF8String) > 1024) {
        return FMMountTargetsFail(error, 2,
                                  @"The mount path is not representable.", 0);
    }
    if (![logicalPath hasPrefix:@"/"] ||
        [logicalPath hasPrefix:@"//"] ||
        ![logicalPath isEqual:logicalPath.stringByStandardizingPath] ||
        FMMountTargetsHasUnsafeComponents(logicalPath)) {
        return FMMountTargetsFail(error, 3,
                                  @"The mount path must be absolute and normalized.",
                                  0);
    }
    if ([logicalPath isEqual:@"/"]) {
        return FMMountTargetsFail(error, 4,
                                  @"The filesystem root cannot be a mount path.",
                                  0);
    }
    if (FMMountTargetsPathsOverlap(logicalPath,
                                   FMMountTargetsSystemFontsPath) ||
        FMMountTargetsPathsOverlap(logicalPath,
                                   FMMountTargetsSupplementalPath) ||
        FMMountTargetsPathsOverlap(logicalPath,
                                   FMMountTargetsFontServicesRoot)) {
        return FMMountTargetsFail(
            error, 5,
            @"The mount path overlaps a font tree managed by MarkFont.", 0);
    }
    if (FMMountTargetsPathsOverlap(logicalPath,
                                   FMMountTargetsStorageMirrorRoot) ||
        FMMountTargetsPathsOverlap(logicalPath,
                                   FMMountTargetsEngineRoot) ||
        FMMountTargetsPathsOverlap(logicalPath,
                                   FMMountTargetsPreferenceRoot)) {
        return FMMountTargetsFail(
            error, 6,
            @"The mount path is inside a MarkFont-owned tree.", 0);
    }
    return YES;
}

BOOL FMMountTargetsValidatePath(NSString *logicalPath, NSError **error) {
    if (!FMMountTargetsValidateStructure(logicalPath, error)) {
        return NO;
    }
    struct stat info = {0};
    errno = 0;
    if (lstat(logicalPath.fileSystemRepresentation, &info) != 0) {
        return FMMountTargetsFail(error, 7,
                                  @"The mount path does not exist.", errno);
    }
    if (!S_ISDIR(info.st_mode) || S_ISLNK(info.st_mode)) {
        return FMMountTargetsFail(
            error, 8, @"The mount path must be a physical directory.", 0);
    }
    return YES;
}

static void FMMountTargetsMakeTreeWritable(NSString *rootPath) {
    if (rootPath.length == 0) return;
    chmod(rootPath.fileSystemRepresentation, 0755);
    NSDirectoryEnumerator *enumerator =
        [NSFileManager.defaultManager enumeratorAtPath:rootPath];
    for (NSString *relativePath in enumerator) {
        NSString *path = [rootPath stringByAppendingPathComponent:relativePath];
        struct stat info = {0};
        if (lstat(path.fileSystemRepresentation, &info) != 0) continue;
        mode_t updated = info.st_mode | S_IWUSR;
        if (S_ISDIR(info.st_mode)) updated |= S_IXUSR;
        if (updated != info.st_mode) {
            chmod(path.fileSystemRepresentation, updated);
        }
    }
}

NSString *FMMountTargetsSourceLogicalPath(NSString *logicalPath) {
    return jbroot(logicalPath);
}

BOOL FMMountTargetsPreparePath(NSString *logicalPath, NSError **error) {
    if (!FMMountTargetsValidatePath(logicalPath, error)) return NO;

    NSString *sourcePath = jbroot(logicalPath);
    struct stat sourceInfo = {0};
    errno = 0;
    if (lstat(sourcePath.fileSystemRepresentation, &sourceInfo) == 0) {
        if (!S_ISDIR(sourceInfo.st_mode) || S_ISLNK(sourceInfo.st_mode)) {
            return FMMountTargetsFail(
                error, 10,
                @"The jbroot source exists but is not a directory.", 0);
        }
        if (geteuid() == 0) FMMountTargetsMakeTreeWritable(sourcePath);
        return YES;
    }
    if (errno != ENOENT) {
        return FMMountTargetsFail(
            error, 11, @"The jbroot source could not be inspected.", errno);
    }
    if (geteuid() != 0) {
        return FMMountTargetsFail(
            error, 20, @"Preparing a mount source requires effective uid 0.",
            EPERM);
    }

    NSFileManager *fileManager = NSFileManager.defaultManager;
    NSString *parent = sourcePath.stringByDeletingLastPathComponent;
    NSError *directoryError = nil;
    if (![fileManager createDirectoryAtPath:parent
                withIntermediateDirectories:YES
                                 attributes:@{NSFilePosixPermissions : @0755}
                                      error:&directoryError]) {
        return FMMountTargetsFail(
            error, 26, @"The jbroot source directory could not be created.",
            (int)directoryError.code);
    }
    chmod(parent.fileSystemRepresentation, 0755);

    // Mirror HelloMnt's copy-on-add behavior: clone the current system tree
    // into the jbroot so the new mapping starts from the original content.
    if (copyfile(logicalPath.fileSystemRepresentation,
                 sourcePath.fileSystemRepresentation, NULL,
                 COPYFILE_ALL | COPYFILE_RECURSIVE) != 0) {
        return FMMountTargetsFail(
            error, 27, @"The system directory could not be copied into the jbroot.",
            errno);
    }
    errno = 0;
    if (lstat(sourcePath.fileSystemRepresentation, &sourceInfo) != 0 ||
        !S_ISDIR(sourceInfo.st_mode) || S_ISLNK(sourceInfo.st_mode)) {
        return FMMountTargetsFail(
            error, 28,
            @"The copied jbroot source is not a physical directory.",
            errno);
    }
    FMMountTargetsMakeTreeWritable(sourcePath);
    return YES;
}

static BOOL FMMountTargetsReadDocument(NSDictionary<NSString *, id> **document,
                                       BOOL *present,
                                       NSError **error) {
    if (present != NULL) *present = NO;
    NSString *path = jbroot(FMMountTargetsConfigurationLogicalPath);
    struct stat info = {0};
    errno = 0;
    if (lstat(path.fileSystemRepresentation, &info) != 0) {
        if (errno == ENOENT) return YES;
        return FMMountTargetsFail(
            error, 10,
            @"The mount path configuration could not be inspected.", errno);
    }
    if (!S_ISREG(info.st_mode) || info.st_uid != 0 ||
        (info.st_mode & (S_IWGRP | S_IWOTH)) != 0) {
        return FMMountTargetsFail(
            error, 11,
            @"The mount path configuration has unsafe metadata.", 0);
    }
    if (present != NULL) *present = YES;
    NSData *data = [NSData dataWithContentsOfFile:path options:0 error:NULL];
    if (data == nil) {
        return FMMountTargetsFail(
            error, 12,
            @"The mount path configuration could not be read.", 0);
    }
    id object = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
    if (![object isKindOfClass:NSDictionary.class]) {
        return FMMountTargetsFail(
            error, 13,
            @"The mount path configuration is not a dictionary.", 0);
    }
    if (![object[@"schemaVersion"] isEqual:@1] ||
        ![object[@"paths"] isKindOfClass:NSArray.class]) {
        return FMMountTargetsFail(
            error, 14,
            @"The mount path configuration is invalid.", 0);
    }
    if (document != NULL) *document = object;
    return YES;
}

NSArray<NSString *> * _Nullable FMMountTargetsConfiguredPaths(NSError **error) {
    NSDictionary<NSString *, id> *document = nil;
    BOOL present = NO;
    if (!FMMountTargetsReadDocument(&document, &present, error)) {
        return nil;
    }
    if (!present || document == nil) {
        return @[];
    }
    NSArray *raw = document[@"paths"];
    if (raw.count > FMMountTargetsMaximumCount) {
        FMMountTargetsFail(error, 15,
                           @"Too many mount paths are configured.", 0);
        return nil;
    }
    NSMutableArray<NSString *> *paths =
        [NSMutableArray arrayWithCapacity:raw.count];
    for (id value in raw) {
        if (!FMMountTargetsValidateStructure(value, error) ||
            [paths containsObject:value]) {
            FMMountTargetsFail(error, 16,
                               @"The mount path list is invalid.", 0);
            return nil;
        }
        [paths addObject:value];
    }
    return paths;
}

BOOL FMMountTargetsPathIsConfigured(NSString *logicalPath) {
    NSArray<NSString *> *paths = FMMountTargetsConfiguredPaths(NULL);
    return paths != nil && [paths containsObject:logicalPath];
}

static BOOL FMMountTargetsWriteDocument(NSDictionary<NSString *, id> *document,
                                       NSError **error) {
    if (geteuid() != 0) {
        return FMMountTargetsFail(
            error, 20,
            @"Changing mount paths requires effective uid 0.", EPERM);
    }
    NSString *path = jbroot(FMMountTargetsConfigurationLogicalPath);
    NSString *directory = path.stringByDeletingLastPathComponent;
    NSError *directoryError = nil;
    if (![NSFileManager.defaultManager
            createDirectoryAtPath:directory
       withIntermediateDirectories:YES
                        attributes:@{NSFilePosixPermissions : @0755}
                             error:&directoryError]) {
        return FMMountTargetsFail(
            error, 27,
            @"The mount path configuration directory could not be created.",
            (int)directoryError.code);
    }
    chmod(directory.fileSystemRepresentation, 0755);
    NSData *data = [NSJSONSerialization dataWithJSONObject:document
                                                  options:NSJSONWritingPrettyPrinted
                                                    error:error];
    if (data == nil) {
        return FMMountTargetsFail(
            error, 21,
            @"The mount path configuration could not be serialized.", 0);
    }
    NSString *temporaryPath =
        [path stringByAppendingFormat:@".%@.tmp", NSUUID.UUID.UUIDString];
    if (![data writeToFile:temporaryPath options:NSDataWritingAtomic error:error]) {
        return FMMountTargetsFail(
            error, 22,
            @"The mount path configuration could not be written.", 0);
    }
    if (chmod(temporaryPath.fileSystemRepresentation, 0644) != 0 ||
        chown(temporaryPath.fileSystemRepresentation, 0, 0) != 0) {
        int savedError = errno;
        unlink(temporaryPath.fileSystemRepresentation);
        return FMMountTargetsFail(
            error, 23,
            @"The mount path configuration could not be secured.", savedError);
    }
    if (rename(temporaryPath.fileSystemRepresentation,
               path.fileSystemRepresentation) != 0) {
        int savedError = errno;
        unlink(temporaryPath.fileSystemRepresentation);
        return FMMountTargetsFail(
            error, 24,
            @"The mount path configuration could not be published.", savedError);
    }
    return YES;
}

BOOL FMMountTargetsWritePaths(NSArray<NSString *> *paths, NSError **error) {
    if (![paths isKindOfClass:NSArray.class]) {
        return FMMountTargetsFail(error, 25,
                                  @"A mount path list is required.", 0);
    }
    if (paths.count > FMMountTargetsMaximumCount) {
        return FMMountTargetsFail(error, 15,
                                  @"Too many mount paths are configured.", 0);
    }
    NSString *configurationPath =
        jbroot(FMMountTargetsConfigurationLogicalPath);
    if (paths.count == 0) {
        if (unlink(configurationPath.fileSystemRepresentation) != 0 &&
            errno != ENOENT) {
            return FMMountTargetsFail(
                error, 30,
                @"The mount path configuration could not be removed.", errno);
        }
        return YES;
    }

    NSMutableSet<NSString *> *unique = [NSMutableSet set];
    for (id value in paths) {
        if (!FMMountTargetsValidateStructure(value, error)) {
            return NO;
        }
        [unique addObject:value];
    }
    NSArray<NSString *> *sorted =
        [unique.allObjects sortedArrayUsingSelector:@selector(compare:)];
    NSISO8601DateFormatter *formatter = [[NSISO8601DateFormatter alloc] init];
    formatter.formatOptions = NSISO8601DateFormatWithInternetDateTime;
    NSDictionary<NSString *, id> *document = @{
        @"schemaVersion" : @1,
        @"paths" : sorted,
        @"updatedAt" : [formatter stringFromDate:NSDate.date],
    };
    return FMMountTargetsWriteDocument(document, error);
}
