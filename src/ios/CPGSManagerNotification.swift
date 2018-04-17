@available(iOS 10.0, *)
class CPGSManagerNotification : NSObject, UNUserNotificationCenterDelegate {
    
    override init() {
        super.init()
        
        UNUserNotificationCenter.current().delegate = self
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        log("CPGSManagerNotification: userNotificationCenter")
        completionHandler([.alert])
    }
    
    static func notify(_ notification: JSON, interval: Double) {
        log("CPGSManagerNotification: notifyAbout")
        
        let content = UNMutableNotificationContent()
        content.title = NSString.localizedUserNotificationString(forKey: notification["title"].stringValue, arguments: nil)
        content.body = NSString.localizedUserNotificationString(forKey: notification["text"].stringValue, arguments: nil)
        content.sound = UNNotificationSound.default()
        content.badge = UIApplication.shared.applicationIconBadgeNumber + 1 as NSNumber;
        content.categoryIdentifier = "CPGS.notify"
        
        var request: UNNotificationRequest? = nil
        // Deliver the notification in five seconds.
        if(interval == 0){
            request = UNNotificationRequest.init(identifier: UUID().uuidString, content: content, trigger: nil)
        }else{
            let trigger = UNTimeIntervalNotificationTrigger.init(timeInterval: interval, repeats: false)
            request = UNNotificationRequest.init(identifier: UUID().uuidString, content: content, trigger: trigger)
        }
        
        // Schedule the notification.
        let center = UNUserNotificationCenter.current()
        center.add(request!)
    }
    
    static func registerUserNotificationSettings(completion: @escaping () -> ()) {
        log("CPGSManagerNotification: registerUserNotificationSettings")
         // Correct
        UNUserNotificationCenter.current().requestAuthorization(options: [.sound, .alert, .badge]) { (granted, error) in
            if error == nil{
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
                
                completion()
            }
        }
    }

    static func removeAll() {
        log("CPGSManagerNotification: removeAll")
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    static func clearBadge() {
        log("CPGSManagerNotification: clearBadge")
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
}
