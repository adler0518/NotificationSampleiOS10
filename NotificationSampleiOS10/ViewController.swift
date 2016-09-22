//
//  ViewController.swift
//  NotificationSampleiOS10
//
//  Created by qitmac000260 on 16/9/22.
//  Copyright © 2016年 jinfeng.du. All rights reserved.
//

import UIKit
import UserNotifications

enum SaySomethingCategoryAction: String {
    case input
    case goodbye
    case none
}

enum CustomizeUICategoryAction: String {
    case `switch`
    case open
    case dismiss
}

class ViewController: UIViewController, UNUserNotificationCenterDelegate {
    var center:UNUserNotificationCenter!
    var identifierIndex = 1
    var curIdentifier:String!
    
    
    // 内存相关
    //MARK: - Memory manager (init, dealloc ...)
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // 类生命周期相关的
    //MARK:  - Life cycle (viewDidLoad ...)
    override func viewDidLoad() {
        super.viewDidLoad()
        
        registerNotificationCategory()
        
        center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { (granted, error) in
            // Enable or disable features based on authorization
            print("adu authorization completion: \(granted)")
        }
        self.addLocalNotification()
//        self.perform(#selector(ViewController.updateLocationNotification), with: "FiveSecond", afterDelay: 6)
        center.delegate = self
        
        center.getNotificationSettings { (UNNotificationSettings) in
            print("adu getNotificationSettings: \(UNNotificationSettings)")
        }
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
    // 类的internal方法(默认为此级别)
    //MARK:  - internal methods (default)
    
    // 所有的Actions
    //MARK:  - Actions
    @IBAction func addRequestNotification() {
        let notificatinId = "custom_identifier_\(identifierIndex)"
        identifierIndex += 1
        self.addLocalNotification(identifier: notificatinId, body: notificatinId)
    }
    
    //更新Notification只需要对已经存在的identifier执行add即可
    @IBAction func updateLocationNotification() -> Void {
        self.addLocalNotification(identifier: self.curIdentifier, body: "update location boday \(identifierIndex)")
        identifierIndex += 1
    }
    
    //添加一条自定义类型的通知
    @IBAction func addCustomLocationNotification(){
        let content = UNMutableNotificationContent()
        content.title = NSString.localizedUserNotificationString(forKey: "Category!", arguments: nil)
        content.subtitle = "副标题看看"
        content.body = NSString.localizedUserNotificationString(forKey:"Please say something", arguments: nil)
        content.sound = UNNotificationSound.default() // Deliver the notification in five seconds.
        content.userInfo = ["name": "Adu Test"]
        content.categoryIdentifier = "saySomethingCategory"
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        let request = UNNotificationRequest(identifier: "customCategoryNoticationId", content: content, trigger: trigger) // Schedule the notification.
        center.add(request)
    }
    
    @IBAction func addCustomUILocationNotification(){
        let content = UNMutableNotificationContent()
        content.title = NSString.localizedUserNotificationString(forKey: "Extension!", arguments: nil)
        content.body = NSString.localizedUserNotificationString(forKey:"Please say something", arguments: nil)
        content.sound = UNNotificationSound.default() // Deliver the notification in five seconds.
        let imageNames = ["image", "name"]
        let attachments = imageNames.flatMap { name -> UNNotificationAttachment? in
            if let imageURL = Bundle.main.url(forResource: name, withExtension: "jpg") {
                return try? UNNotificationAttachment(identifier: "image-\(name)", url: imageURL, options: nil)
            }
            return nil
        }
        
        content.attachments = attachments
        content.userInfo = ["items": [["title": "Photo 1", "text": "火影"], ["title": "Photo 2", "text": "我爱罗"]]]
        

        content.categoryIdentifier = "customUI"
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        let request = UNNotificationRequest(identifier: "customUI", content: content, trigger: trigger) // Schedule the notification.
        center.add(request)
    }
    
    // 通知回调，具体可以细分
    //MARK:  - Notifications - XXX
    
    // 系统的Delegate
    //MARK:  - UNUserNotificationCenterDelegate
    //前台的时候，收到Notification首先调用此接口，可以在这里处理是否展示及如何展示
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("adu willPresent: \(notification)")
        
        
        
        completionHandler([.sound, .alert])
    }
    
    //点击了通知栏中的通知后，进入应用时先调用此方法
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print("adu didReceive: \(response)")
        
        if let name = response.notification.request.content.userInfo["name"] as? String {
            print("I know it's you! \(name)")
        }
        
        if let category =  response.notification.request.content.categoryIdentifier as? String {
            if category == "saySomethingCategory" {
                handleSaySomthing(response: response)
            }
        }
        
        //什么也不做，告诉系统你已经完成了所有工作
        completionHandler()
    }
    
    // 自定义类的Delegate
    //MARK:  - XXXDelegate
    
    // 自定义View、初始化等
    //MARK:  - Custom views
    private func registerNotificationCategory() {
        let saySomethingCategory: UNNotificationCategory = {
            // 1
            let inputAction = UNTextInputNotificationAction(
                identifier: SaySomethingCategoryAction.input.rawValue,
                title: "Input",
                options: [.foreground],
                textInputButtonTitle: "Send",
                textInputPlaceholder: "What do you want to say...")
            
            // 2
            let goodbyeAction = UNNotificationAction(
                identifier: SaySomethingCategoryAction.goodbye.rawValue,
                title: "Goodbye",
                options: [.foreground])
            
            let cancelAction = UNNotificationAction(
                identifier: SaySomethingCategoryAction.none.rawValue,
                title: "Cancel",
                options: [.destructive])
            
            // 3
            return UNNotificationCategory(identifier:"saySomethingCategory", actions: [inputAction, goodbyeAction, cancelAction], intentIdentifiers: [], options: [.customDismissAction])
        }()
        
        let customUICategory: UNNotificationCategory = {
            let nextAction = UNNotificationAction(
                identifier: CustomizeUICategoryAction.switch.rawValue,
                title: "Switch",
                options: [])
            let openAction = UNNotificationAction(
                identifier: CustomizeUICategoryAction.open.rawValue,
                title: "Open",
                options: [.foreground])
            let dismissAction = UNNotificationAction(
                identifier: CustomizeUICategoryAction.dismiss.rawValue,
                title: "Dismiss",
                options: [.destructive])
            return UNNotificationCategory(identifier: "customUI", actions: [nextAction, openAction, dismissAction], intentIdentifiers: [], options: [])
        }()
        
        UNUserNotificationCenter.current().setNotificationCategories([saySomethingCategory, customUICategory])
    }
    
    // 类私有方法
    //MARK:  - Private methods
    //添加一条本地通知
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
    
    func removeNotification(identifier: String) -> Void {
        print("adu Notification request removed: \(identifier)")
        
        //移除已经展示的通知（即移除通知栏中的某个通知）
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [identifier])
    }
    
    
    private func handleSaySomthing(response: UNNotificationResponse) {
        let text: String
        
        if let actionType = SaySomethingCategoryAction(rawValue: response.actionIdentifier) {
            switch actionType {
            case .input: text = (response as! UNTextInputNotificationResponse).userText
            case .goodbye: text = "Goodbye"
            case .none: text = ""
            }
        } else {
            // Only tap or clear. (You will not receive this callback when user clear your notification unless you set .customDismissAction as the option of category)
            text = ""
        }
        
        if !text.isEmpty {
            UIAlertController.showConfirmAlertFromTopViewController(message: "You just said \(text)")
        }
    }

}

