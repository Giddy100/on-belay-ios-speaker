import Foundation
import Combine
import UserNotifications

class MainViewModel: ObservableObject {
    @Published var firebase = FirebaseService.shared

    @Published var selectedGroupId: String = ""
    @Published var selectedGroup: Group?
    @Published var hasNotificationPermission: Bool? = nil

    private var cancellables = Set<AnyCancellable>()

    init() {
        checkNotificationPermission()
        Publishers.CombineLatest(firebase.$userSettings, firebase.$userGroups)
            .first { settings, groups in
                settings != nil && !groups.isEmpty
            }
            .sink { [weak self] settings, groups in
                guard let self = self, let settings = settings else { return }

                let groupId = settings.selectedGroupId ?? ""
                self.selectedGroupId = groupId
                self.updateSelectedGroup(id: groupId)
            }
            .store(in: &cancellables)

        Publishers.CombineLatest(firebase.$userSettings, firebase.$userGroups)
            .dropFirst()
            .sink { [weak self] settings, groups in
                if let settings = settings {
                    let groupId = settings.selectedGroupId ?? ""
                    if self?.selectedGroupId != groupId {
                        self?.selectedGroupId = groupId
                    }
                }
                self?.updateSelectedGroup(id: self?.selectedGroupId)
            }
            .store(in: &cancellables)
    }

    private func updateSelectedGroup(id: String?) {
        if let id = id, !id.isEmpty {
            self.selectedGroup = firebase.userGroups.first { $0.groupId == id }
        } else {
            self.selectedGroup = nil
        }
    }

    func checkNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                switch settings.authorizationStatus {
                case .authorized, .provisional, .ephemeral:
                    self.hasNotificationPermission = true
                case .denied:
                    self.hasNotificationPermission = false
                case .notDetermined:
                    self.requestNotificationPermission()
                @unknown default:
                    self.hasNotificationPermission = false
                }
            }
        }
    }

    private func requestNotificationPermission() {
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound, .criticalAlert]
        UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { granted, _ in
            DispatchQueue.main.async {
                self.hasNotificationPermission = granted
            }
        }
    }

    func syncWithMain() {
        firebase.refreshUserData()
    }
}
