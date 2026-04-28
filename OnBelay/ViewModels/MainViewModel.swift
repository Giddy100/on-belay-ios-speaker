import Foundation
import Combine

class MainViewModel: ObservableObject {
    @Published var firebase = FirebaseService.shared
    @Published var speech = SpeechService.shared

    @Published var selectedGroup: Group?
    @Published var isActive: Bool = false

    private var cancellables = Set<AnyCancellable>()

    init() {
        firebase.$userSettings
            .sink { [weak self] settings in
                if let settings = settings {
                    self?.isActive = settings.isActive
                    self?.updateSelectedGroup(id: settings.selectedGroupId)
                }
            }
            .store(in: &cancellables)

        firebase.$userGroups
            .sink { [weak self] _ in
                self?.updateSelectedGroup(id: self?.firebase.userSettings?.selectedGroupId)
            }
            .store(in: &cancellables)
    }

    private func updateSelectedGroup(id: String?) {
        if let id = id, !id.isEmpty {
            self.selectedGroup = firebase.userGroups.first { $0.groupId == id }
        } else {
            self.selectedGroup = nil
        }

        speech.setup(
            wakeupPhrase: firebase.userSettings?.wakeupPhrase ?? "Hey Moses",
            selectedGroup: self.selectedGroup,
            volume: Float(firebase.userSettings?.volume ?? 1.0)
        )
    }

    func toggleActive() {
        guard selectedGroup != nil else { return }
        isActive.toggle()

        Task {
            await firebase.setUserSettings(["isActive": isActive])
            if isActive {
                speech.logs = []
                speech.startListening()
            } else {
                speech.stopListening()
            }
        }
    }

    func selectGroup(_ group: Group) {
        Task {
            await firebase.setUserSettings(["selectedGroupId": group.groupId])
            updateSelectedGroup(id: group.groupId)
        }
    }
}
