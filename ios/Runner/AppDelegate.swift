import UIKit
import Flutter
import UserNotifications
import FirebaseMessaging
import FirebaseCore
import Foundation
import StoreKit
import GoogleMobileAds

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var methodChannel: FlutterMethodChannel?
  private var adMethodChannel: FlutterMethodChannel?
  private var backgroundTaskIdentifier: UIBackgroundTaskIdentifier = .invalid
  private var interstitialAd: InterstitialAd?
  private var rewardedAd: RewardedAd?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    startBackgroundTask(application: application)
    FirebaseApp.configure()
    
    // Initialize Google Mobile Ads
    MobileAds.shared.start { status in
      print("Google Mobile Ads initialization completed with status: \(status.adapterStatusesByClassName)")
    }

    #if DEBUG
    if let configURL = Bundle.main.url(forResource: "Configuration", withExtension: "storekit") {
      do {
        // CRITICAL FIX: Clear any pending transactions before setting up StoreKit testing
        print("Clearing pending StoreKit transactions...")
        clearPendingTransactions()
        
        try SKPaymentQueue.default().setStorekit2TransactionListenerForTesting()
        try SKAdImpression.enabledForTesting()
        print("StoreKit configuration loaded successfully for testing!")
        
        // Add additional transaction queue management
        setupTransactionQueueManagement()
        
      } catch {
        print("StoreKit configuration loading failed: \(error.localizedDescription)")
      }
    } else {
      print("StoreKit configuration file not found in the bundle!")
    }
    #else
    // For production builds, also ensure clean transaction queue
    clearPendingTransactions()
    setupTransactionQueueManagement()
    #endif

    GeneratedPluginRegistrant.register(with: self)

    if let controller = window?.rootViewController as? FlutterViewController {
      methodChannel = FlutterMethodChannel(
        name: "com.flutterflow.lunakraft/firebase_messaging",
        binaryMessenger: controller.binaryMessenger)
        
      // Setup AdMob method channel
      adMethodChannel = FlutterMethodChannel(
        name: "com.flutterflow.lunakraft/admob",
        binaryMessenger: controller.binaryMessenger
      )
      
      setupAdMobMethodChannel(controller: controller)
    }

    if #available(iOS 10.0, *) {
      let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound, .provisional]
      UNUserNotificationCenter.current().requestAuthorization(
        options: authOptions,
        completionHandler: { granted, error in
          print("Notification permission granted: \(granted)")
          if let error = error {
            print("Notification permission error: \(error.localizedDescription)")
          }
        }
      )
      UNUserNotificationCenter.current().delegate = self
    } else {
      let settings: UIUserNotificationSettings =
        UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
      application.registerUserNotificationSettings(settings)
    }

    application.registerForRemoteNotifications()
    Messaging.messaging().delegate = self
    Messaging.messaging().isAutoInitEnabled = true
    endBackgroundTask()

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  private func setupAdMobMethodChannel(controller: FlutterViewController) {
    adMethodChannel?.setMethodCallHandler { [weak self] (call, result) in
      guard let self = self else {
        result(FlutterError(code: "UNAVAILABLE", 
                           message: "AppDelegate instance is not available", 
                           details: nil))
        return
      }
      
      switch call.method {
      case "loadInterstitialAd":
        self.loadInterstitialAd { success in
          result(success)
        }
        
      case "showInterstitialAd":
        self.showInterstitialAd { success in
          result(success)
        }
        
      case "loadRewardedAd":
        self.loadRewardedAd { success in
          result(success)
        }
        
      case "showRewardedAd":
        self.showRewardedAd { success, reward in
          if success {
            result(["success": true, "amount": reward])
          } else {
            result(["success": false, "amount": 0])
          }
        }
        
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
  
  private func loadInterstitialAd(completion: @escaping (Bool) -> Void) {
    // Use specified ad unit ID for interstitial ads
    let adUnitID = "ca-app-pub-3406090070128457/9972039967" // Interstitial ad ID from screenshot
    
    let request = Request()
    InterstitialAd.load(with: adUnitID, request: request) { [weak self] ad, error in
      if let error = error {
        print("Failed to load interstitial ad with error: \(error.localizedDescription)")
        completion(false)
        return
      }
      
      self?.interstitialAd = ad
      print("Interstitial ad loaded successfully")
      completion(true)
    }
  }
  
  private func showInterstitialAd(completion: @escaping (Bool) -> Void) {
    guard let interstitialAd = interstitialAd else {
      print("Interstitial ad not loaded yet")
      completion(false)
      return
    }
    
    guard let rootViewController = UIApplication.shared.windows.first?.rootViewController else {
      print("Root view controller not found")
      completion(false)
      return
    }
    
    interstitialAd.present(from: rootViewController)
    print("Interstitial ad presented")
    completion(true)
  }
  
  private func loadRewardedAd(completion: @escaping (Bool) -> Void) {
    // Use production rewarded ad ID for Luna Kraft
    let adUnitID = "ca-app-pub-3406090070128457/9972039967" // Production rewarded ad ID
    
    let request = Request()
    RewardedAd.load(with: adUnitID, request: request) { [weak self] ad, error in
      if let error = error {
        print("Failed to load rewarded ad with error: \(error.localizedDescription)")
        completion(false)
        return
      }
      
      self?.rewardedAd = ad
      print("Rewarded ad loaded successfully")
      completion(true)
    }
  }
  
  private func showRewardedAd(completion: @escaping (Bool, Int) -> Void) {
    guard let rewardedAd = rewardedAd else {
      print("Rewarded ad not loaded yet")
      completion(false, 0)
      return
    }
    
    guard let rootViewController = UIApplication.shared.windows.first?.rootViewController else {
      print("Root view controller not found")
      completion(false, 0)
      return
    }
    
    rewardedAd.present(from: rootViewController, userDidEarnRewardHandler: { 
      let reward = rewardedAd.adReward
      print("Rewarded ad presented. Reward: \(reward.amount) \(reward.type)")
      completion(true, reward.amount.intValue)
    })
  }

  private func startBackgroundTask(application: UIApplication) {
    endBackgroundTask()
    backgroundTaskIdentifier = application.beginBackgroundTask(withName: "AppStartupTask") {
      self.endBackgroundTask()
    }
    print("Started background task with identifier: \(backgroundTaskIdentifier.rawValue)")
  }

  private func endBackgroundTask() {
    if backgroundTaskIdentifier != .invalid {
      UIApplication.shared.endBackgroundTask(backgroundTaskIdentifier)
      backgroundTaskIdentifier = .invalid
      print("Ended background task")
    }
  }

  override func applicationWillTerminate(_ application: UIApplication) {
    endBackgroundTask()
    print("Application terminating")
  }

  override func application(_ application: UIApplication,
                          didReceiveRemoteNotification userInfo: [AnyHashable : Any],
                          fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
    print("Remote notification received in background: \(userInfo)")
    Messaging.messaging().appDidReceiveMessage(userInfo)
    if let methodChannel = methodChannel {
      do {
        let jsonData = try JSONSerialization.data(withJSONObject: userInfo, options: [])
        if let jsonString = String(data: jsonData, encoding: .utf8) {
          methodChannel.invokeMethod("didReceiveRemoteNotification", arguments: jsonString)
        }
      } catch {
        print("Error converting notification to JSON: \(error)")
      }
    }
    completionHandler(.newData)
  }

  override func application(_ application: UIApplication,
                          didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
    let token = tokenParts.joined()
    print("Device Token: \(token)")
    Messaging.messaging().apnsToken = deviceToken
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  override func application(_ application: UIApplication,
                          didFailToRegisterForRemoteNotificationsWithError error: Error) {
    print("Failed to register for remote notifications: \(error.localizedDescription)")
  }

  override func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    let userInfo = notification.request.content.userInfo
    print("Will present notification: \(userInfo)")
    Messaging.messaging().appDidReceiveMessage(userInfo)
    completionHandler([[.banner, .badge, .sound]])
  }

  override func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
    let userInfo = response.notification.request.content.userInfo
    print("Did receive notification response: \(userInfo)")
    Messaging.messaging().appDidReceiveMessage(userInfo)
    completionHandler()
  }
  
  // MARK: - StoreKit Transaction Queue Management
  
  /// Clears any pending transactions from the StoreKit queue to prevent transaction mismatches
  private func clearPendingTransactions() {
    let paymentQueue = SKPaymentQueue.default()
    let pendingTransactions = paymentQueue.transactions
    
    print("Found \(pendingTransactions.count) pending transactions in queue")
    
    for transaction in pendingTransactions {
      print("Pending transaction: \(transaction.transactionIdentifier ?? "unknown") for product: \(transaction.payment.productIdentifier)")
      
      // Only finish transactions that are in a completed or failed state
      switch transaction.transactionState {
      case .purchased, .restored:
        print("Finishing completed transaction: \(transaction.transactionIdentifier ?? "unknown")")
        paymentQueue.finishTransaction(transaction)
      case .failed:
        print("Finishing failed transaction: \(transaction.transactionIdentifier ?? "unknown")")
        paymentQueue.finishTransaction(transaction)
      case .purchasing, .deferred:
        print("Leaving active transaction in queue: \(transaction.transactionIdentifier ?? "unknown")")
      @unknown default:
        print("Unknown transaction state for: \(transaction.transactionIdentifier ?? "unknown")")
      }
    }
    
    print("Transaction queue cleanup completed")
  }
  
  /// Sets up additional transaction queue management to prevent RevenueCat conflicts
  private func setupTransactionQueueManagement() {
    // Add observer to monitor transaction queue changes
    let paymentQueue = SKPaymentQueue.default()
    
    // Log current queue state
    print("Current transaction queue state:")
    print("- Transactions in queue: \(paymentQueue.transactions.count)")
    
    for transaction in paymentQueue.transactions {
      print("- Transaction: \(transaction.transactionIdentifier ?? "unknown"), Product: \(transaction.payment.productIdentifier), State: \(transactionStateString(transaction.transactionState))")
    }
    
    // Set up periodic queue monitoring (only in debug mode)
    #if DEBUG
    Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
      self.monitorTransactionQueue()
    }
    #endif
  }
  
  /// Monitors the transaction queue for potential issues
  private func monitorTransactionQueue() {
    let paymentQueue = SKPaymentQueue.default()
    let transactions = paymentQueue.transactions
    
    if !transactions.isEmpty {
      print("Transaction queue monitor - Found \(transactions.count) transactions:")
      for transaction in transactions {
        print("- \(transaction.transactionIdentifier ?? "unknown"): \(transaction.payment.productIdentifier) (\(transactionStateString(transaction.transactionState)))")
      }
    }
  }
  
  /// Helper method to convert transaction state to readable string
  private func transactionStateString(_ state: SKPaymentTransactionState) -> String {
    switch state {
    case .purchasing:
      return "purchasing"
    case .purchased:
      return "purchased"
    case .failed:
      return "failed"
    case .restored:
      return "restored"
    case .deferred:
      return "deferred"
    @unknown default:
      return "unknown"
    }
  }
}

extension AppDelegate: MessagingDelegate {
  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    print("Firebase registration token: \(fcmToken ?? "nil")")
    let dataDict: [String: String] = ["token": fcmToken ?? ""]
    NotificationCenter.default.post(
      name: Notification.Name("FCMToken"),
      object: nil,
      userInfo: dataDict
    )
    if let methodChannel = methodChannel, let token = fcmToken {
      methodChannel.invokeMethod("updateFCMToken", arguments: token)
    }
  }
}

