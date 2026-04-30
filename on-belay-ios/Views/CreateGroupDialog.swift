import SwiftUI
import FirebaseAuth

struct CreateGroupDialog: View {
    @Binding var isPresented: Bool
    @State private var name = ""
    @State private var code = ""
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(7 * 24 * 60 * 60)
    @State private var phrases: [Phrase] = []
    @State private var showingPhrases = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(NSLocalizedString("name", comment: ""), text: $name)
                    TextField(NSLocalizedString("code", comment: ""), text: $code)
                        .keyboardType(.numberPad)
                        .onChange(of: code) { _, newValue in
                            if newValue.count > 4 {
                                code = String(newValue.prefix(4))
                            }
                        }
                }

                Section {
                    DatePicker(NSLocalizedString("start_date", comment: ""), selection: $startDate, displayedComponents: .date)
                    DatePicker(NSLocalizedString("end_date", comment: ""), selection: $endDate, displayedComponents: .date)
                }

                Button(action: { showingPhrases = true }) {
                    Text(NSLocalizedString("phrases", comment: ""))
                }
            }
            .navigationTitle(NSLocalizedString("create_group", comment: ""))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("cancel", comment: "")) { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(NSLocalizedString("create", comment: "")) {
                        createGroup()
                    }
                    .disabled(name.isEmpty || code.count != 4 || !isDateRangeValid)
                }
            }
            .sheet(isPresented: $showingPhrases) {
                PhrasesDialog(phrases: $phrases, isCreator: true)
            }
            .task {
                phrases = await FirebaseService.shared.getDefaultPhrases()
            }
        }
    }

    var isDateRangeValid: Bool {
        let diff = endDate.timeIntervalSince(startDate)
        return diff > 0 && diff <= 30 * 24 * 60 * 60
    }

    func createGroup() {
        let group = Group(
            groupId: UUID().uuidString,
            name: name,
            createdByName: FirebaseService.shared.userSettings?.name ?? "",
            code: code,
            startDate: startDate.timeIntervalSince1970 * 1000,
            endDate: endDate.timeIntervalSince1970 * 1000,
            phrases: phrases,
            createdByUid: FirebaseService.shared.currentUser?.uid ?? "",
            joinedUsers: []
        )
        Task {
            if await FirebaseService.shared.createGroup(group) {
                isPresented = false
            }
        }
    }
}
