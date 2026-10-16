import FirebaseCore
import FirebaseMessaging
import UIKit
import UserNotifications
import OSLog

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    static var authorizationTask: Task<Bool, Never>?
    private static let logger = Logger(subsystem: "com.twinkletown.sparklefriends", category: "notifications")

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseApp.configure()
        Messaging.messaging().delegate = self
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        Self.authorizationTask = Task {
            let settings = await center.notificationSettings()
            do {
                let granted: Bool
                if settings.authorizationStatus == .notDetermined {
                    Self.logger.info("Requesting notification permission")
                    granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
                } else {
                    granted = [.authorized, .provisional, .ephemeral].contains(settings.authorizationStatus)
                }
                Self.logger.info("Notification permission granted: \(granted)")
                if granted {
                    Messaging.messaging().isAutoInitEnabled = true
                    application.registerForRemoteNotifications()
                } else {
                    Messaging.messaging().isAutoInitEnabled = false
                }
                return granted
            } catch {
                Self.logger.error("Notification permission failed: \(error.localizedDescription)")
                return false
            }
        }
        return true
    }


    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
        Self.logger.info("APNs registration succeeded")
        Messaging.messaging().token { token, error in
            if let error { Self.logger.error("FCM registration failed: \(error.localizedDescription)") }
            Task { await PushTokenStore.shared.setToken(token) }
        }
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        Self.logger.error("APNs registration failed: \(error.localizedDescription)")
    }

    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        OrientationLock.current
    }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
                                           willPresent notification: UNNotification,
                                           withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .list, .sound, .badge])
    }
}

extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        Self.logger.info("FCM token received: \(fcmToken != nil)")
        Task { await PushTokenStore.shared.setToken(fcmToken) }
    }
}
