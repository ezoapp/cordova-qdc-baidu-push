
#import "BaiduPushPlugin.h"
#import "BPush.h"

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

@implementation BaiduPushPlugin{
    NSNotificationCenter *_onbindObserver;    
}

- (void)startWork:(CDVInvokedUrlCommand*)command{
    NSLog(@"startWork...");
    
    self.startWorkCallbackId = command.callbackId;
    
    NSString *apiKey = command.arguments[0];
    NSString *mode = command.arguments[1];
    BPushMode pushMode = (mode != (id)[NSNull null] && [mode caseInsensitiveCompare:@"production"] == NSOrderedSame) ? BPushModeProduction : BPushModeDevelopment; 
    [BPush registerChannel:nil apiKey: apiKey pushMode:pushMode withFirstAction:nil withSecondAction:nil withCategory:nil isDebug:YES];

    if (_onbindObserver != nil) {
        [[NSNotificationCenter defaultCenter] removeObserver:_onbindObserver];
    }

    _onbindObserver = [[NSNotificationCenter defaultCenter] addObserverForName:CBType_onbind
                object:nil
                queue:[NSOperationQueue mainQueue]
                usingBlock:^(NSNotification *note) {
                    NSLog(@"onbind callback...");
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
}

- (void)registerForRemoteNotifications {
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0) {
        if ([[UIApplication sharedApplication]respondsToSelector:@selector(registerUserNotificationSettings:)]) {
            UIUserNotificationType UserNotificationTypes = UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert;
            UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:UserNotificationTypes categories:nil];
            [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
            [[UIApplication sharedApplication] registerForRemoteNotifications];
        } else {
            [[UIApplication sharedApplication] registerForRemoteNotificationTypes:
            (UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
        }
    } else {
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:
        (UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];        
    }    
}

- (void)receiveNotificationWithType:(NSString *)type  {
    if (self.startWorkCallbackId && self.notificationMessage) {
        NSLog(@"receive Notification: %@, withType: %@", self.notificationMessage, type);
        // handle notification with baidu push
        [BPush handleNotification:self.notificationMessage];
        
        NSMutableDictionary* message = [NSMutableDictionary dictionaryWithCapacity:3];
        NSMutableDictionary* payload = [NSMutableDictionary dictionaryWithCapacity:4];

        for (id key in self.notificationMessage) {
            if ([key isEqualToString:@"aps"]) {
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
        
        [message setObject:type forKey:ResultKey_type];
        [message setObject:payload forKey:ResultKey_payload];

        // send notification message
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:message];
        [pluginResult setKeepCallbackAsBool:YES];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.startWorkCallbackId];

        self.notificationMessage = nil;
    }
}

- (void)stopWork:(CDVInvokedUrlCommand*)command{
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
}

- (void)resumeWork:(CDVInvokedUrlCommand*)command{
    NSLog(@"resumeWork...");
    
    [self registerForRemoteNotifications];
    
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_NO_RESULT];
    [pluginResult setKeepCallbackAsBool:YES];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
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

@end
