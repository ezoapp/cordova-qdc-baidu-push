
#import <Foundation/Foundation.h>
#import <Cordova/CDV.h>
#import <Cordova/CDVPlugin.h>

extern NSString* const CBType_onbind;
extern NSString* const CBType_onunbind;
extern NSString* const CBType_onmessage;
extern NSString* const CBType_onnotificationclicked;
extern NSString* const CBType_onnotificationarrived;
extern NSString* const CBType_onsettags;
extern NSString* const CBType_ondeltags;
extern NSString* const CBType_onlisttags;

@interface BaiduPushPlugin : CDVPlugin

@property (nonatomic, copy) NSString *startWorkCallbackId;
@property (nonatomic, strong) NSDictionary *notificationMessage;
@property (nonatomic, strong) NSMutableDictionary *handlerObj;
 
/*!
 @method
 @abstract 绑定
 */
- (void)startWork:(CDVInvokedUrlCommand*)command;

/*!
 @method
 @abstract 解除绑定
 */
- (void)stopWork:(CDVInvokedUrlCommand*)command;

/*!
 @method
 @abstract 回复绑定
 */
- (void)resumeWork:(CDVInvokedUrlCommand*)command;

/*!
@method
@abstract 设置Tag
*/
- (void)setTags:(CDVInvokedUrlCommand*)command;

/*!
 @method
 @abstract 删除Tag
 */
- (void)delTags:(CDVInvokedUrlCommand*)command;

- (void)listTags:(CDVInvokedUrlCommand*)command;

- (void)receiveNotificationWithType:(NSString *)type;

- (void)disableLbs;

@end