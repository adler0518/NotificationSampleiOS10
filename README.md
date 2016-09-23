# NotificationSampleiOS10

# 简介
iOS 10中以前杂乱的通知相关API被统一了，现在可以使用UserNotifications.framework 来管理和使用iOS系统通知功能。在此基础上，Apple 还增加了撤回单条通知，更新已展示通知，中途修改通知内容，在通知中展示图片视频，自定义通知 UI 等一系列新功能，非常强大。

您可以在 WWDC 16 的 [Introduction to Notifications](https://developer.apple.com/videos/play/wwdc2016/707/) 和 [Advanced Notifications](https://developer.apple.com/videos/play/wwdc2016/708/) 这两个 Session 中找到详细信息；另外也不要忘了参照 [UserNotifications](https://developer.apple.com/reference/usernotifications) 的官方文档以及本文的实例项目 NotificationSampleiOS10。

##用法
###申请APNs tonken
这个还是保持原来的申请方式，在`application:didFinishLaunchingWithOptions:`中进行申请：
>UIApplication.shared.registerForRemoteNotifications() 

并且实现
`application:didRegisterForRemoteNotificationsWithDeviceToken:`将`deviceToken`传递给server

###注册通知
	center = UNUserNotificationCenter.current()
	center.requestAuthorization(options: [.alert, .sound]) 	{ (granted, error) in
    	// Enable or disable features based on authorization
    	print("adu authorization completion: \(granted)")
	}
###Notification settings
之前注册推送服务，用户点击了确定还是取消，已经之后用户之后做了修改我们都是无感知的，现在我们可以获取到用户设置的信息了。

	center.getNotificationSettings { (UNNotificationSettings) in
        print("adu getNotificationSettings: \(UNNotificationSettings)")
    }
    
打印的日志

	<UNNotificationSettings: 0x16567310; 
		authorizationStatus: Authorized, 
		notificationCenterSetting: Enabled, 
		soundSetting: Enabled, 
		badgeSetting: Enabled, 
		lockScreenSetting: Enabled, 
		alertSetting: NotSupported,
		carPlaySetting: Enabled, 
		alertStyle: Banner>
		
###创建并且发送一条本地通知
	
	func addLocalNotification(identifier: String = "FiveSecond", body:String = "Hello_message_body") {
        let content = UNMutableNotificationContent()
        content.title = NSString.localizedUserNotificationString(forKey: "Hello!", arguments: nil)
        content.subtitle = "副标题看看"
        content.body = NSString.localizedUserNotificationString(forKey:body, arguments: nil)
        content.sound = UNNotificationSound.default() // Deliver the notification in five seconds.
        content.userInfo = ["name": "Adu Test"]
        
        if identifier == "FiveSecond" {
            if let imageURL = Bundle.main.url(forResource: "name", withExtension: "jpg"),
                let attachment = try? UNNotificationAttachment(identifier: "imageAttachment", url: imageURL, options: nil)
            {
                content.attachments = [attachment]
            }
        }
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger) // Schedule the notification.
        center.add(request)
        
        self.curIdentifier = identifier
        
        print("adu add a location notification");
    }
`UNMutableNotificationContent`用于承载push的具体内容及设置，本地通知和APNs系统的同样适用。`attachments`通知中展示图片或者视频。

###attachments - 带图片或者视频的PUSH
`UNNotificationAttachment`,在创建 UNNotificationAttachment 时我们只能使用本地资源，所以，如果是网络图片或者音频则需要先将其下载到本地再加载。如果是remote通知在`payload`来指明图片，按照`UNNotificationServiceExtension`在push显示之前将其下载到本地再展示。
`attachments`是个数组，push展示只展示第一个，不过可以通过`UNNotificationContentExtension`来实现切换，可参看demo中的`NotificationViewController.swift`类。


**读取：**`attachment`内容的读取，需要注意权限问题。可以使用 startAccessingSecurityScopedResource 来暂时获取以创建的 attachment 的访问权限。* 
	
 
    let content = notification.request.content
    if let attachment = content.attachments.first {
        if attachment.url.startAccessingSecurityScopedResource() {
            eventImage.image = UIImage(contentsOfFile: attachment.url.path!)
            attachment.url.stopAccessingSecurityScopedResource()
        }
    }

**限制**： [这些文件都有尺寸的限制，音频不能超过5MB, 图片不能超过 10MB，视频不能超过 50MB。](https://developer.apple.com/reference/usernotifications/UNNotificationAttachment)

**options选项：**

	//配置附件的类型的键 需要设置为NSString类型的值，如果不设置 则默认从扩展名中推断
    extern NSString * const UNNotificationAttachmentOptionsTypeHintKey __IOS_AVAILABLE(10.0) __WATCHOS_AVAILABLE(3.0);
    //配置是否隐藏缩略图的键 需要配置为NSNumber 0或者1
    extern NSString * const UNNotificationAttachmentOptionsThumbnailHiddenKey __IOS_AVAILABLE(10.0) __WATCHOS_AVAILABLE(3.0);
    //配置使用一个标准的矩形来对缩略图进行裁剪，需要配置为CGRectCreateDictionaryRepresentation(CGRect)创建的矩形引用
    extern NSString * const UNNotificationAttachmentOptionsThumbnailClippingRectKey __IOS_AVAILABLE(10.0) __WATCHOS_AVAILABLE(3.0);
    //使用视频中的某一帧作为缩略图 配置为NSNumber时间
    extern NSString * const UNNotificationAttachmentOptionsThumbnailTimeKey __IOS_AVAILABLE(10.0) __WATCHOS_AVAILABLE(3.0);


###推送过程
*Local Notifications 通过定义 `Content` 和 `Trigger` 向  `UNUserNotificationCenter` 进行 `request` 这三部曲来实现。

*Remote Notifications 则向 `APNs` 发送 `Notification Payload`.

###Triggers
有四种类型：延时触发`UNTimeIntervalNotificationTrigger`，指定日期触发 `UNCalendarNotificationTrigger`，根据位置触发，进入或者离开某个位置都会触发`UNLocationNotificationTrigger`（从而可以实现地理围栏通知的需求了），`UNPushNotificationTrigger` 触发APNS服务，系统自动设置（这是区分本地通知和远程通知的标识）

	//2 分钟后提醒
    UNTimeIntervalNotificationTrigger *trigger1 = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:120 repeats:NO];

    //每小时重复 1 次喊我喝水
    UNTimeIntervalNotificationTrigger *trigger2 = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:3600 repeats:YES];

    //每周一早上 8：00 提醒我给老婆做早饭
    NSDateComponents *components = [[NSDateComponents alloc] init];
    components.weekday = 2;
    components.hour = 8;
    UNCalendarNotificationTrigger *trigger3 = [UNCalendarNotificationTrigger triggerWithDateMatchingComponents:components repeats:YES];

    //#import <CoreLocation/CoreLocation.h>
    //一到麦当劳就喊我下车
    CLRegion *region = [[CLRegion alloc] init];
    UNLocationNotificationTrigger *trigger4 = [UNLocationNotificationTrigger triggerWithRegion:region repeats:NO];

###payload
[可以查看官网](https://developer.apple.com/library/content/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/Chapters/TheNotificationPayload.html)

    {
        "aps":{
            "alert":{
                "title":"Image Notification",
                "body":"Show me an image from web!"
            },
            "mutable-content":1
        },
        "image": "https://onevcat.com/assets/images/background-cover.jpg"
    }
    
###通知的修改和删除

指定相同`UNNotificationRequest.identifier`,实现对已有通知的更新，包括已经展现和未展现的。

`UNUserNotificationCenter.removeDeliveredNotifications`删除已经展现的通知，即通知中心中消失掉。`UNUserNotificationCenter.removePendingNotificationRequests`，删除已经add但是还没有显示的通知。

###Notification Extension

iOS 10中增加了`UNNotificationServiceExtension`和`UNNotificationContentExtension`分别实现对远程通知和本地通知的自定义。

remote push 到达后，首先会调用`UNNotificationServiceExtension的didReceiveNotificationRequest`方法,**此方法系统给的最大时间是30秒**，如果超时则会执行`UNNotificationServiceExtension的serviceExtensionTimeWillExpire`方法。
> // Call contentHandler with the modified notification content to deliver. If the handler is not called before the service's time expires then the unmodified notification will be delivered.
// You are expected to override this method to implement push notification modification.

>- (void)didReceiveNotificationRequest:(UNNotificationRequest *)request withContentHandler:(void (^)(UNNotificationContent *contentToDeliver))contentHandler;

>// Will be called just before this extension is terminated by the system. You may choose whether to override this method.

>- (void)serviceExtensionTimeWillExpire;

**remote push，包换网络图片或视频资源，则需要通过上面的方式先下载处理**

###UNNotificationCategory
使用`UNNotificationCategory`来创建扩展类，程序启动或者在使用之前将其添加到通知中心:
>`UNUserNotificationCenter.current().setNotificationCategories([saySomethingCategory, customUICategory])`

定义好了通知UI模板，若要进行使用，还需要再Notification Content扩展中的info.plist文件的NSExtension字典的NSExtensionAttributes字典里进行一些配置，正常情况下，开发者需要进行配置的键有3个，分别如下：

1. UNNotificationExtensionCategory：设置模板的categoryId，用于与UNNotificationContent对应。
2. UNNotificationExtensionInitialContentSizeRatio：设置自定义通知界面的高度与宽度的比，宽度为固定宽度，在不同设备上有差别，开发者需要根据宽度计算出高度进行设置，系统根据这个比值来计算通知界面的高度。
3. UNNotificationExtensionDefaultContentHidden：是有隐藏系统默认的通知界面，不设置为不隐藏。

**注意：** 要使用模板`UNNotificationCategory`，通知内容UNNotificationContent的categoryIdentifier要与UNNotificationCategory的id一致


### 适配
支持iOS 10，则需要做代码适配，等以后升级到10之后就可以删除原来的旧方式代码了。

	if #available(iOS 10.0, *) {
    	// Use UserNotification
	}
	




