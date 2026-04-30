import SwiftUI

struct MainSettingsDialog: View {
    @Binding var isPresented: Bool
    @State private var name = FirebaseService.shared.userSettings?.name ?? ""
    @State private var volume = FirebaseService.shared.userSettings?.volume ?? 1.0

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text(NSLocalizedString("name", comment: ""))) {
                    TextField(NSLocalizedString("name", comment: ""), text: $name)
                }

                Section(header: Text(NSLocalizedString("volume", comment: ""))) {
                    Slider(value: $volume, in: 0...1)
                }

                Section {
                    Button(action: switchUser) {
                        Text(NSLocalizedString("switch_user", comment: ""))
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle(NSLocalizedString("main_settings", comment: ""))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("cancel", comment: "")) { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(NSLocalizedString("save", comment: "")) { saveSettings() }
                        .disabled(name.isEmpty)
                }
            }
        }
    }

    func saveSettings() {
        Task {
            await FirebaseService.shared.setUserSettings(["name": name, "volume": volume])
            isPresented = false
        }
    }

    func switchUser() {
        FirebaseService.shared.signOut()
        isPresented = false
    }
}
