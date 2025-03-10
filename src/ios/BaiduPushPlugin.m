
#import "BaiduPushPlugin.h"
#import "BPush.h"
#ifdef NSFoundationVersionNumber_iOS_9_x_Max
#import <UserNotifications/UserNotifications.h>
#endif

NSString* const CBType_onbind = @"onbind";
NSString* const CBType_onunbind = @"onunbind";
NSString* const CBType_onmessage = @"onmessage";
NSString* const CBType_onnotificationclicked = @"onnotificationclicked";
NSString* const CBType_onnotificationarrived = @"onnotificationarrived";
NSString* const CBType_onsettags = @"onsettags";
NSString* const CBType_ondeltags = @"ondeltags";
NSString* const CBType_onlisttags = @"onlisttags";

NSString* const ResultKey_type = @"type";
NSString* const ResultKey_appId = @"appId";
NSString* const ResultKey_userId = @"userId";
NSString* const ResultKey_channelId = @"channelId";
NSString* const ResultKey_requestId = @"requestId";
NSString* const ResultKey_successTags = @"successTags";
NSString* const ResultKey_failTags = @"failTags";
NSString* const ResultKey_tags = @"tags";
NSString* const ResultKey_payload = @"payload";

@implementation BaiduPushPlugin {
    NSNotificationCenter *_onbindObserver;    
}

@synthesize startWorkCallbackId;
@synthesize notificationMessage;
@synthesize handlerObj;

- (void)startWork:(CDVInvokedUrlCommand*)command
{
    [self.commandDelegate runInBackground:^ {
        NSLog(@"startWork...");
    
        self.startWorkCallbackId = command.callbackId;
        
        NSString *apiKey = command.arguments[0];
        NSString *mode = command.arguments[1];
        BPushMode pushMode = (mode != (id)[NSNull null] && [mode caseInsensitiveCompare:@"production"] == NSOrderedSame) ? BPushModeProduction : BPushModeDevelopment; 
        [BPush registerChannel:nil apiKey: apiKey pushMode:pushMode withFirstAction:nil withSecondAction:nil withCategory:nil useBehaviorTextInput:NO isDebug:YES];

        if (_onbindObserver != nil) {
            [[NSNotificationCenter defaultCenter] removeObserver:_onbindObserver];
        }

        _onbindObserver = [[NSNotificationCenter defaultCenter] addObserverForName:CBType_onbind
                    object:nil
                    queue:[NSOperationQueue mainQueue]
                    usingBlock:^(NSNotification *note) {
                        NSLog(@"onbind callback block...");
                        id obj = [note object];

                        if ([obj isKindOfClass:[NSError class]]) {
                            NSError *error = (NSError *) obj;
                            CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:[error localizedDescription]];
                            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                            return;
                        }

                        NSData *deviceToken = (NSData *) obj;
                        [BPush registerDeviceToken:deviceToken];

                        [BPush bindChannelWithCompleteHandler:^(id result, NSError *error) {
                            NSLog(@"bindChannelWithCompleteHandler...");
                            CDVPluginResult* pluginResult;
                            if ([self checkBaiduResult:result]) {
                                NSMutableDictionary* message = [NSMutableDictionary dictionaryWithCapacity:6];
                                [message setObject:CBType_onbind forKey:ResultKey_type];
                                [message setObject:[BPush getAppId] forKey:ResultKey_appId];
                                [message setObject:[BPush getUserId] forKey:ResultKey_userId];
                                [message setObject:[BPush getChannelId] forKey:ResultKey_channelId];
                                [message setObject:result[BPushRequestRequestIdKey] forKey:ResultKey_requestId];
                            
                                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:message];
                                [pluginResult setKeepCallbackAsBool:YES];
                            } else {
                                NSString* message = result[BPushRequestErrorMsgKey];
                                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:message];
                            }
                            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                        }];

                    }];

        [self registerForRemoteNotifications];

        // if there is a pending startup notification
        if (self.notificationMessage) {			
            dispatch_async(dispatch_get_main_queue(), ^{
                // delay to allow JS event handlers to be setup
                [self performSelector:@selector(receiveNotification) withObject:nil afterDelay: 0.5];
            });
        }

    }];
}

- (void)registerForRemoteNotifications {
    NSLog(@"registerForRemoteNotifications...");
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 10.0) {
#ifdef NSFoundationVersionNumber_iOS_9_x_Max
        UNUserNotificationCenter* center = [UNUserNotificationCenter currentNotificationCenter];
        
        [center requestAuthorizationWithOptions:(UNAuthorizationOptionAlert + UNAuthorizationOptionSound + UNAuthorizationOptionBadge)
                              completionHandler:^(BOOL granted, NSError * _Nullable error) {
                                  // Enable or disable features based on authorization.
                                  if (granted) {
                                      [[UIApplication sharedApplication] registerForRemoteNotifications];
                                  }
                              }];
#endif
    } else if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0 &&
            [[UIApplication sharedApplication]respondsToSelector:@selector(registerUserNotificationSettings:)]) {

        UIUserNotificationType UserNotificationTypes = UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert;
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:UserNotificationTypes categories:nil];
        [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
        [[UIApplication sharedApplication] registerForRemoteNotifications];

    } else {
        UIUserNotificationType UserNotificationTypes = UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert;
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:UserNotificationTypes];      
    }    
}

- (void)receiveNotification {
    if (self.startWorkCallbackId && self.notificationMessage) {
        NSLog(@"receive Notification: %@", self.notificationMessage);
        // handle notification with baidu push
        [BPush handleNotification:self.notificationMessage];
        
        NSMutableDictionary* message = [NSMutableDictionary dictionaryWithCapacity:4];
        NSMutableDictionary* payload = [NSMutableDictionary dictionaryWithCapacity:4];

        for (id key in self.notificationMessage) {

            if ([key isEqualToString:ResultKey_type]) {
                id type = [self.notificationMessage objectForKey:ResultKey_type];
                [message setObject:type forKey:ResultKey_type];

            } else if ([key isEqualToString:@"aps"]) {
                id aps = [self.notificationMessage objectForKey:@"aps"];

                for(id apsKey in aps) {
                    id apsValue = [aps objectForKey:apsKey];
                    if ([apsKey isEqualToString:@"alert"]) {
                        if ([apsValue isKindOfClass:[NSDictionary class]]) {
                            for (id messageKey in apsValue) {
                                [payload setObject:[apsValue objectForKey:messageKey] forKey:messageKey];
                            }
                        } else {
                            [payload setObject:apsValue forKey:apsKey];
                        }
                        
                    } else {
                        [payload setObject:apsValue forKey:apsKey];
                    }
                }
                
            } else {
                if (key != (id)[NSNull null] && [key length] != 0) {
                    [payload setObject:[self.notificationMessage objectForKey:key] forKey:key];
                }
            }
        }
        
        [message setObject:payload forKey:ResultKey_payload];

        // send notification message
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:message];
        [pluginResult setKeepCallbackAsBool:YES];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.startWorkCallbackId];

        self.notificationMessage = nil;
    }
}

- (void)stopWork:(CDVInvokedUrlCommand*)command
{
    [self.commandDelegate runInBackground:^ {
        NSLog(@"stopWork...");
        
        [[UIApplication sharedApplication] unregisterForRemoteNotifications];
        
        [BPush unbindChannelWithCompleteHandler:^(id result, NSError *error) {
            CDVPluginResult* pluginResult;
            if ([self checkBaiduResult:result]) {
                NSMutableDictionary* message = [NSMutableDictionary dictionaryWithCapacity:3];
                [message setObject:CBType_onunbind forKey:ResultKey_type];
                [message setObject:result[BPushRequestRequestIdKey] forKey:ResultKey_requestId];
            
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:message];
                [pluginResult setKeepCallbackAsBool:YES];
            } else {
                NSString* message = result[BPushRequestErrorMsgKey];
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:message];
            }
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        }];
    }];        
}

- (void)resumeWork:(CDVInvokedUrlCommand*)command
{
    [self.commandDelegate runInBackground:^ {
        NSLog(@"resumeWork...");
        
        [self registerForRemoteNotifications];
        
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_NO_RESULT];
        [pluginResult setKeepCallbackAsBool:YES];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];
}

- (void)setTags:(CDVInvokedUrlCommand*)command{
    NSLog(@"setTags...");
    
    NSArray *tags = command.arguments;
    if (tags) {
        [BPush setTags:tags withCompleteHandler:^(id result, NSError *error) {
            CDVPluginResult* pluginResult;
            if ([self checkBaiduResult:result]) {
                NSMutableArray* successTagArray = [[NSMutableArray alloc] init];
                NSMutableArray* failTagArray = [[NSMutableArray alloc] init];
                for (id tag in [result[BPushRequestResponseParamsKey] objectForKey:@"details"]) {
                    if ([[tag[@"result"] stringValue] isEqualToString:@"0"]){
                        [successTagArray addObject:tag[@"tag"]];    
                    } else {
                        [failTagArray addObject:tag[@"tag"]];    
                    }
                }                
                
                NSMutableDictionary* message = [NSMutableDictionary dictionaryWithCapacity:6];
                [message setObject:CBType_onsettags forKey:ResultKey_type];
                [message setObject:successTagArray forKey:ResultKey_successTags];            
                [message setObject:failTagArray forKey:ResultKey_failTags];            
                [message setObject:result[BPushRequestRequestIdKey] forKey:ResultKey_requestId];                
                
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:message];
                [pluginResult setKeepCallbackAsBool:YES];
            } else {
                NSString* message = result[BPushRequestErrorMsgKey];
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:message];                
            }
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        }];
    }
}

- (void)delTags:(CDVInvokedUrlCommand*)command{
    NSLog(@"delTags...");
    
    NSArray *tags = command.arguments;
    if (tags) {
        [BPush delTags:tags withCompleteHandler:^(id result, NSError *error) {
            CDVPluginResult* pluginResult;
            if ([self checkBaiduResult:result]) {
                NSMutableArray* successTagArray = [[NSMutableArray alloc] init];
                NSMutableArray* failTagArray = [[NSMutableArray alloc] init];
                for (id tag in [result[BPushRequestResponseParamsKey] objectForKey:@"details"]) {
                    if ([[tag[@"result"] stringValue] isEqualToString:@"0"]){
                        [successTagArray addObject:tag[@"tag"]];    
                    } else {
                        [failTagArray addObject:tag[@"tag"]];    
                    }
                }                
                
                NSMutableDictionary* message = [NSMutableDictionary dictionaryWithCapacity:6];
                [message setObject:CBType_ondeltags forKey:ResultKey_type];
                [message setObject:successTagArray forKey:ResultKey_successTags];            
                [message setObject:failTagArray forKey:ResultKey_failTags];            
                [message setObject:result[BPushRequestRequestIdKey] forKey:ResultKey_requestId];                
                
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:message];
                [pluginResult setKeepCallbackAsBool:YES];
            } else {
                NSString* message = result[BPushRequestErrorMsgKey];
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:message];                
            }
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        }];
    }
}

- (void)listTags:(CDVInvokedUrlCommand*)command{
    NSLog(@"listTags...");
    
    [BPush listTagsWithCompleteHandler:^(id result, NSError *error) {
        CDVPluginResult* pluginResult;
        if ([self checkBaiduResult:result]) {
            NSMutableArray* tagArray = [[NSMutableArray alloc] init];
            for (id tag in [result[BPushRequestResponseParamsKey] objectForKey:ResultKey_tags]) {
                [tagArray addObject:tag[@"name"]];
            }
            
            NSMutableDictionary* message = [NSMutableDictionary dictionaryWithCapacity:5];
            [message setObject:CBType_onlisttags forKey:ResultKey_type];
            [message setObject:tagArray forKey:ResultKey_tags];            
            [message setObject:result[BPushRequestRequestIdKey] forKey:ResultKey_requestId];
            
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:message];        
            [pluginResult setKeepCallbackAsBool:YES];
        } else {
            NSString* message = result[BPushRequestErrorMsgKey];
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:message];
        }        
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];
}

- (BOOL)checkBaiduResult:(id)result{
    id errorCode = result[BPushRequestErrorCodeKey];
    if (errorCode == 0 || [[errorCode description] isEqualToString:@"0"]){
        return YES;
    }
    return NO;
}

- (void)disableLbs {
    NSLog(@"disableLbs...");
    // 禁用地理位置推送 需要再绑定接口前调用。
    [BPush disableLbs];
}

-(void) finish:(CDVInvokedUrlCommand*)command
{
    NSLog(@"Push Plugin finish called");

    [self.commandDelegate runInBackground:^ {
        NSString* notId = [command.arguments objectAtIndex:0];

        dispatch_async(dispatch_get_main_queue(), ^{
            [NSTimer scheduledTimerWithTimeInterval:0.1
                                             target:self
                                           selector:@selector(stopBackgroundTask:)
                                           userInfo:notId
                                            repeats:NO];
        });

        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];
}

-(void)stopBackgroundTask:(NSTimer*)timer
{
    UIApplication *app = [UIApplication sharedApplication];

    NSLog(@"Push Plugin stopBackgroundTask called");

    if (handlerObj) {
        NSLog(@"Push Plugin handlerObj");
        completionHandler = [handlerObj[[timer userInfo]] copy];
        if (completionHandler) {
            NSLog(@"Push Plugin: stopBackgroundTask (remaining t: %f)", app.backgroundTimeRemaining);
            completionHandler(UIBackgroundFetchResultNewData);
            completionHandler = nil;
        }
    }
}

@end
