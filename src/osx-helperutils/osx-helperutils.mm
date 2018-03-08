#import <Cocoa/Cocoa.h>
#import <Security/Authorization.h>
#import <ServiceManagement/ServiceManagement.h>
#include <QtGlobal>

#import "src/osx-helperutils/helper-client.h"
#import "src/osx-helperutils/osx-helperutils.h"
#import "utils/objc-defines.h"

#if !__has_feature(objc_arc)
#error this file must be built with ARC support
#endif

@interface SMJobBlessHelper : NSObject {
    AuthorizationRef _authRef;
}

- (BOOL)install;
- (BOOL)blessHelperWithLabel:(NSString *)label error:(NSError **)errorPtr;
- (void)dealloc;
@end

@implementation SMJobBlessHelper

- (void)dealloc
{
    printf("dealloc is called!\n");
}

- (BOOL)install
{
    NSError *error = nil;

    OSStatus status = AuthorizationCreate(NULL,
                                          kAuthorizationEmptyEnvironment,
                                          kAuthorizationFlagDefaults,
                                          &self->_authRef);
    if (status != errAuthorizationSuccess) {
        /* AuthorizationCreate really shouldn't fail. */
        self->_authRef = NULL;
        NSError *error = [NSError errorWithDomain:NSOSStatusErrorDomain
                                             code:status
                                         userInfo:nil];
        qWarning("failed to initialize helper tool: %s",
                 NSERROR_TO_CSTR(error));
        return false;
    }

    if (![self blessHelperWithLabel:@"com.seafile.seadrive.helper"
                              error:&error]) {
        qWarning("Failed to install seadrive helper: %s",
                 NSERROR_TO_CSTR(error));
        return false;
    } else {
        /* At this point, the job is available. However, this is a very
         * simple sample, and there is no IPC infrastructure set up to
         * make it launch-on-demand. You would normally achieve this by
         * using XPC (via a MachServices dictionary in your launchd.plist).
         */
        NSLog(@"Job is available!");
        return true;
    }
}

- (BOOL)blessHelperWithLabel:(NSString *)label error:(NSError **)errorPtr
{
    BOOL result = NO;
    NSError *error = nil;

    AuthorizationItem authItem = {kSMRightBlessPrivilegedHelper, 0, NULL, 0};
    AuthorizationRights authRights = {1, &authItem};
    AuthorizationFlags flags =
        kAuthorizationFlagDefaults | kAuthorizationFlagInteractionAllowed |
        kAuthorizationFlagPreAuthorize | kAuthorizationFlagExtendRights;

    /* Obtain the right to install our privileged helper tool
     * (kSMRightBlessPrivilegedHelper). */
    OSStatus status = AuthorizationCopyRights(self->_authRef,
                                              &authRights,
                                              kAuthorizationEmptyEnvironment,
                                              flags,
                                              NULL);
    if (status != errAuthorizationSuccess) {
        error = [NSError errorWithDomain:NSOSStatusErrorDomain
                                    code:status
                                userInfo:nil];
    } else {
        CFErrorRef cfError;

        /* This does all the work of verifying the helper tool against the
         * application
         * and vice-versa. Once verification has passed, the embedded
         * launchd.plist
         * is extracted and placed in /Library/LaunchDaemons and then loaded.
         * The
         * executable is placed in /Library/PrivilegedHelperTools.
         */
        result = (BOOL)SMJobBless(kSMDomainSystemLaunchd,
                                  (__bridge CFStringRef)label,
                                  self->_authRef,
                                  &cfError);
        if (!result) {
            error = CFBridgingRelease(cfError);
        }
    }
    if (!result && (errorPtr != NULL)) {
        assert(error != nil);
        *errorPtr = error;
    }

    return result;
}

@end

bool installHelperTool()
{
    // TODO: do not reinstall the helper tool each time seadrive-gui is launched
    SMJobBlessHelper *helper = [[SMJobBlessHelper alloc] init];
    return [helper install];
}

bool installKext(bool *finished, bool *ok)
{
    HelperClient *c = new HelperClient();
    return c->installKext(finished, ok);
}
