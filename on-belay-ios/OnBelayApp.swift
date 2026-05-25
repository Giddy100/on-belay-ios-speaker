import SwiftUI
import Foundation
import FirebaseCore
import FirebaseMessaging
import GoogleSignIn

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()

        // Push Notifications
        UNUserNotificationCenter.current().delegate = self
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound, .criticalAlert]
        UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { _, _ in }
        application.registerForRemoteNotifications()

        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error.localizedDescription)")
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        print("Push notification received with payload \(userInfo)")

        // Handle playing sound based on payload if app is in foreground
        if let soundFile = userInfo["iphoneFileId"] as? String {
            let volume = Float(FirebaseService.shared.userSettings?.volume ?? 1.0)
            AudioService.shared.playSound(soundFile, volume: volume)
        }

        completionHandler([[.banner, .list, .sound]])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        print("Push notification without notification payload")
        completionHandler()
    }
}

@main
struct OnBelayApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject var firebaseService = FirebaseService.shared

    var body: some Scene {
        WindowGroup {
            PermissionGuardView {
                if firebaseService.currentUser != nil {
                    MainScreen()
                        .environment(\.layoutDirection, isHebrew ? .rightToLeft : .leftToRight)
                } else {
                    LoginView()
                        .environment(\.layoutDirection, isHebrew ? .rightToLeft : .leftToRight)
                }
            }
            .onOpenURL { url in
                GIDSignIn.sharedInstance.handle(url)
            }
        }
    }

    var isHebrew: Bool {
        Locale.current.language.languageCode?.identifier == "he"
    }
}
