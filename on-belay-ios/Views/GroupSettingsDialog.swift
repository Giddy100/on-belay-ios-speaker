import SwiftUI
import FirebaseAuth

struct GroupSettingsDialog: View {
    @Binding var isPresented: Bool
    @State var group: Group
    @State private var showingPhrases = false
    @State private var showingDeleteAlert = false
    @State private var showingLeaveAlert = false

    var isCreator: Bool {
        group.createdByUid == FirebaseService.shared.currentUser?.uid
    }

    var body: some View {
        NavigationStack {
            Form {
                if isCreator {
                    Section {
                        TextField(NSLocalizedString("name", comment: ""), text: $group.name)
                        TextField(NSLocalizedString("code", comment: ""), text: Binding(
                            get: { group.code ?? "" },
                            set: { group.code = String($0.prefix(4)) }
                        ))
                        .keyboardType(.numberPad)
                    }

                    Section {
                        DatePicker(NSLocalizedString("start_date", comment: ""), selection: Binding(
                            get: { group.startAsDate },
                            set: { group.startDate = $0.timeIntervalSince1970 * 1000 }
                        ), displayedComponents: .date)
                        DatePicker(NSLocalizedString("end_date", comment: ""), selection: Binding(
                            get: { group.endAsDate },
                            set: { group.endDate = $0.timeIntervalSince1970 * 1000 }
                        ), displayedComponents: .date)
                    }
                } else {
                    Section {
                        LabeledContent(NSLocalizedString("name", comment: ""), value: group.name)
                        Text(String(format: NSLocalizedString("group_starts_ends", comment: ""),
                                    formatDate(group.startAsDate),
                                    formatDate(group.endAsDate)))
                            .font(.subheadline)
                    }
                }

                Button(action: { showingPhrases = true }) {
                    Text(NSLocalizedString("phrases", comment: ""))
                }

                Section {
                    if isCreator {
                        Button(role: .destructive, action: { showingDeleteAlert = true }) {
                            Text(NSLocalizedString("delete_group", comment: ""))
                        }
                    } else {
                        Button(role: .destructive, action: { showingLeaveAlert = true }) {
                            Text(NSLocalizedString("leave_group", comment: ""))
                        }
                    }
                }
            }
            .navigationTitle(NSLocalizedString("settings", comment: ""))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("cancel", comment: "")) { isPresented = false }
                }
                if isCreator {
                    ToolbarItem(placement: .confirmationAction) {
                        Button(NSLocalizedString("update", comment: "")) { updateGroup() }
                            .disabled(group.name.isEmpty || (group.code?.count ?? 0) != 4)
                    }
                }
            }
            .sheet(isPresented: $showingPhrases) {
                PhrasesDialog(phrases: Binding($group.phrases)!, isCreator: isCreator)
            }
            .alert(NSLocalizedString("are_you_sure_delete", comment: ""), isPresented: $showingDeleteAlert) {
                Button(NSLocalizedString("yes", comment: ""), role: .destructive) { deleteGroup() }
                Button(NSLocalizedString("no", comment: ""), role: .cancel) {}
            }
            .alert(NSLocalizedString("are_you_sure_leave", comment: ""), isPresented: $showingLeaveAlert) {
                Button(NSLocalizedString("yes", comment: ""), role: .destructive) { leaveGroup() }
                Button(NSLocalizedString("no", comment: ""), role: .cancel) {}
            }
        }
    }

    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    func updateGroup() {
        Task {
            if await FirebaseService.shared.updateGroup(group) {
                isPresented = false
            }
        }
    }

    func deleteGroup() {
        Task {
            if await FirebaseService.shared.deleteGroup(groupId: group.groupId) {
                isPresented = false
            }
        }
    }

    func leaveGroup() {
        Task {
            if await FirebaseService.shared.leaveGroup(groupId: group.groupId) {
                isPresented = false
            }
        }
    }
}
