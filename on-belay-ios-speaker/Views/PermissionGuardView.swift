import SwiftUI
import UserNotifications

struct PermissionGuardView<Content: View>: View {
    @State private var hasNotificationPermission = false
    @State private var checkTrigger = false

    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var allPermissionsGranted: Bool {
        hasNotificationPermission
    }

    var body: some View {
        if allPermissionsGranted {
            content
        } else {
            VStack(spacing: 20) {
                Text(NSLocalizedString("permissions_required", comment: ""))
                    .font(.title)
                    .bold()

                Text(NSLocalizedString("permissions_message_notifications", comment: ""))
                    .multilineTextAlignment(.center)
                    .padding()

                Button(NSLocalizedString("open_settings", comment: "")) {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .buttonStyle(.borderedProminent)

                Button(NSLocalizedString("check_again", comment: "")) {
                    checkPermissions()
                }
            }
            .padding()
            .onAppear {
                checkPermissions()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                checkPermissions()
            }
        }
    }

    func checkPermissions() {
        // Notifications
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.hasNotificationPermission = settings.authorizationStatus == .authorized
                if !self.hasNotificationPermission {
                    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge, .criticalAlert]) { _, _ in
                        checkPermissions()
                    }
                }
            }
        }
    }
}
