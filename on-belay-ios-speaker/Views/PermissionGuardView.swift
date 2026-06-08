import SwiftUI
import Speech
import AVFAudio

struct PermissionGuardView<Content: View>: View {
    @State private var hasMicrophonePermission = false
    @State private var hasSpeechPermission = false
    @State private var hasNotificationPermission = false
    @State private var checkTrigger = false

    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var allPermissionsGranted: Bool {
        hasMicrophonePermission && hasSpeechPermission && hasNotificationPermission
    }

    var body: some View {
        if allPermissionsGranted {
            content
        } else {
            VStack(spacing: 20) {
                Text(NSLocalizedString("permissions_required", comment: ""))
                    .font(.title)
                    .bold()

                Text(NSLocalizedString("permissions_message", comment: ""))
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
        // Microphone
        if #available(iOS 17.0, *) {
            hasMicrophonePermission = AVAudioApplication.shared.recordPermission == .granted
            if !hasMicrophonePermission {
                AVAudioApplication.requestRecordPermission { _ in
                    checkPermissions()
                }
            }
        } else {
            hasMicrophonePermission = AVAudioSession.sharedInstance().recordPermission == .granted
            if !hasMicrophonePermission {
                AVAudioSession.sharedInstance().requestRecordPermission { _ in
                    checkPermissions()
                }
            }
        }

        // Speech
        hasSpeechPermission = SFSpeechRecognizer.authorizationStatus() == .authorized
        if !hasSpeechPermission {
            SFSpeechRecognizer.requestAuthorization { _ in
                checkPermissions()
            }
        }

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
