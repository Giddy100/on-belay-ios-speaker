import Foundation
import Combine

class MainViewModel: ObservableObject {
    @Published var firebase = FirebaseService.shared
    @Published var speech = SpeechService.shared

    @Published var selectedGroupId: String = ""
    @Published var selectedGroup: Group?
    @Published var isActive: Bool = false

    private var cancellables = Set<AnyCancellable>()

    init() {
        Publishers.CombineLatest(firebase.$userSettings, firebase.$userGroups)
            .sink { [weak self] settings, groups in
                if let settings = settings {
                    self?.isActive = settings.isActive
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
            self.isActive = false // Deactivate if no group is selected
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

    func selectGroup(id: String) {
        guard id != selectedGroupId else { return }
        selectedGroupId = id
        updateSelectedGroup(id: id)

        Task {
            await firebase.setUserSettings(["selectedGroupId": id])
        }
    }
}
