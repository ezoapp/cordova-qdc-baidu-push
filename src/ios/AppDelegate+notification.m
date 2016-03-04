
#import "AppDelegate+notification.h"
#import "BaiduPushPlugin.h"
#import <objc/runtime.h>

static char launchNotificationKey;

@implementation AppDelegate (notification)

- (id) getCommandInstance:(NSString*)className
{
    return [self.viewController getCommandInstance:className];
}

// its dangerous to override a method from within a category.
// Instead we will use method swizzling. we set this up in the load call.
+ (void)load
{
    Method original, swizzled;

    original = class_getInstanceMethod(self, @selector(init));
    swizzled = class_getInstanceMethod(self, @selector(swizzled_init));
    method_exchangeImplementations(original, swizzled);
}

- (AppDelegate *)swizzled_init
{
    NSNotificationCenter *observer = [[NSNotificationCenter defaultCenter] addObserverForName:@"UIApplicationDidFinishLaunchingNotification" 
        object: nil
        queue:[NSOperationQueue mainQueue]
        usingBlock:^(NSNotification *note) {
            NSLog(@"UIApplicationDidFinishLaunchingNotification... %@", note);
            if (note) {
                NSDictionary *launchOptions = [note userInfo];
                if (launchOptions) {
                    self.launchNotification = [launchOptions objectForKey: @"UIApplicationLaunchOptionsRemoteNotificationKey"];
                }
            }    
    }];
                                            
    return [self swizzled_init];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    NSLog(@"didRegisterForRemoteNotificationsWithDeviceToken: %@", deviceToken);    
    [[NSNotificationCenter defaultCenter] postNotificationName:CBType_onbind object:deviceToken];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    NSLog(@"didFailToRegisterForRemoteNotificationsWithError: %@", error);
    [[NSNotificationCenter defaultCenter] postNotificationName:CBType_onbind object:error];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo 
fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    NSLog(@"didReceiveRemoteNotification...");

    // app is in the foreground so call notification callback
    if (application.applicationState == UIApplicationStateActive) {
        NSLog(@"app active");
        BaiduPushPlugin *pushHandler = [self getCommandInstance:@"BaiduPush"];
        pushHandler.notificationMessage = userInfo;
        [pushHandler receiveNotificationWithType:CBType_onnotificationarrived];

        completionHandler(UIBackgroundFetchResultNewData);
    }
    // app is in background or in stand by
    else {
        NSLog(@"app in-active");

        // do some convoluted logic to find out if this should be a silent push.
        long silent = 0;
        id aps = [userInfo objectForKey:@"aps"];
        id contentAvailable = [aps objectForKey:@"content-available"];
        if ([contentAvailable isKindOfClass:[NSString class]] && [contentAvailable isEqualToString:@"1"]) {
            silent = 1;
        } else if ([contentAvailable isKindOfClass:[NSNumber class]]) {
            silent = [contentAvailable integerValue];
        }

        if (silent == 1) {
            NSLog(@"this should be a silent push");
            void (^safeHandler)(UIBackgroundFetchResult) = ^(UIBackgroundFetchResult result){
                dispatch_async(dispatch_get_main_queue(), ^{
                    completionHandler(result);
                });
            };

            NSMutableDictionary* params = [NSMutableDictionary dictionaryWithCapacity:2];
            [params setObject:safeHandler forKey:@"handler"];

            BaiduPushPlugin *pushHandler = [self getCommandInstance:@"BaiduPush"];
            pushHandler.notificationMessage = userInfo;
            pushHandler.handlerObj = params;
            [pushHandler receiveNotificationWithType:CBType_onmessage];
        } else {
            NSLog(@"just put it in the shade");
            //save it for later
            self.launchNotification = userInfo;

            completionHandler(UIBackgroundFetchResultNewData);
        }
    }
    
}

- (BOOL)userHasRemoteNotificationsEnabled 
{
    UIApplication *application = [UIApplication sharedApplication];
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        return application.currentUserNotificationSettings.types != UIUserNotificationTypeNone;
    } else {
        return application.enabledRemoteNotificationTypes != UIRemoteNotificationTypeNone;
    }
}

- (void)applicationDidBecomeActive:(UIApplication *)application 
{
    NSLog(@"active");
    // clear badge number
    application.applicationIconBadgeNumber = 0;

    BaiduPushPlugin *pushHandler = [self getCommandInstance:@"BaiduPush"];    

    if (self.launchNotification) {
        pushHandler.notificationMessage = self.launchNotification;
        self.launchNotification = nil;
        [pushHandler performSelectorOnMainThread:@selector(receiveNotificationWithType:) withObject:CBType_onnotificationclicked waitUntilDone:NO];
    }
}


- (void)application:(UIApplication *) application handleActionWithIdentifier: (NSString *) identifier
forRemoteNotification: (NSDictionary *) notification completionHandler: (void (^)()) completionHandler 
{
    NSLog(@"Push Plugin handleActionWithIdentifier %@", identifier);
    NSMutableDictionary *userInfo = [notification mutableCopy];
    [userInfo setObject:identifier forKey:@"callback"];
    BaiduPushPlugin *pushHandler = [self getCommandInstance:@"BaiduPush"];
    pushHandler.notificationMessage = userInfo;
    [pushHandler receiveNotificationWithType:CBType_onnotificationclicked];

    // Must be called when finished
    completionHandler();
}

- (NSMutableArray *)launchNotification
{
    return objc_getAssociatedObject(self, &launchNotificationKey);
}

- (void)setLaunchNotification:(NSDictionary *)aDictionary
{
    objc_setAssociatedObject(self, &launchNotificationKey, aDictionary, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)dealloc
{
    // clear the association and release the object
    self.launchNotification = nil; 
}

@end
