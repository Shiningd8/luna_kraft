import FirebaseMessaging
import UserNotifications

class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = request.content.mutableCopy() as? UNMutableNotificationContent
        
        guard let bestAttemptContent = bestAttemptContent else { 
            contentHandler(request.content)
            return 
        }
        
        // Log the notification for debugging
        print("NotificationService received notification: \(request.content.userInfo)")
        
        // Ensure we have a mutable copy to manipulate
        guard let userInfo = request.content.userInfo as? [String: Any] else {
            contentHandler(bestAttemptContent)
            return
        }
        
        // Add sound if not present
        if bestAttemptContent.sound == nil {
            bestAttemptContent.sound = UNNotificationSound.default
        }
        
        // Use Firebase helper to process rich media if available
        FIRMessagingExtensionHelper().populateNotificationContent(
          bestAttemptContent,
          withContentHandler: contentHandler)
        
        // If the notification doesn't have category, set a default one 
        if bestAttemptContent.categoryIdentifier.isEmpty {
            bestAttemptContent.categoryIdentifier = "luna_kraft_category"
        }
        
        // Ensure thread id is set for proper grouping
        if bestAttemptContent.threadIdentifier.isEmpty {
            bestAttemptContent.threadIdentifier = "luna_kraft_thread"
        }
        
        // Make sure we have a badge number if notification permission includes badges
        if bestAttemptContent.badge == nil {
            bestAttemptContent.badge = 1
        }
        
        // Deliver the notification if it hasn't been delivered by Firebase helper
        if self.contentHandler != nil {
            self.contentHandler?(bestAttemptContent)
        }
    }
    
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler, let bestAttemptContent = bestAttemptContent {
            // Add debugging statement
            print("NotificationService time will expire - delivering best attempt content")
            contentHandler(bestAttemptContent)
        }
    }
}
