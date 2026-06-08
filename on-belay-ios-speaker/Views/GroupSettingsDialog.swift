import SwiftUI
import FirebaseAuth

struct GroupSettingsDialog: View {
    @Binding var isPresented: Bool
    @State var group: Group
    @State private var showingDeleteAlert = false
    @State private var showingLeaveAlert = false
    @State private var showingMembers = false

    var isCreator: Bool {
        group.createdByUid == FirebaseService.shared.currentUser?.uid
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { isPresented = false }) {
                        Image(systemName: "arrow.left")
                            .foregroundColor(.appActiveGreen)
                            .font(.title3)
                            .flipsForRightToLeftLayoutDirection(true)
                    }
                    Text(NSLocalizedString("settings", comment: ""))
                        .font(.appHeadlineMd())
                        .foregroundColor(.appOnSurface)
                        .padding(.leading, 8)
                    Spacer()
                }
                .padding(.horizontal, AppTheme.marginMobile)
                .padding(.top, 20)
                .padding(.bottom, 24)

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Name
                        VStack(alignment: .leading, spacing: 8) {
                            Text(NSLocalizedString("name", comment: "").uppercased())
                                .font(.appLabelCaps())
                                .foregroundColor(.appOnSurfaceVariant)
                            if isCreator {
                                TextField("", text: $group.name)
                                    .font(.appBodyLg())
                                    .foregroundColor(.appOnSurface)
                                    .padding()
                                    .background(Color.appSurfaceContainer)
                                    .cornerRadius(AppTheme.cornerRadiusMd)
                            } else {
                                Text(group.name)
                                    .font(.appBodyLg())
                                    .foregroundColor(.appOnSurface)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.appSurfaceContainer)
                                    .cornerRadius(AppTheme.cornerRadiusMd)
                            }
                        }

                        if isCreator {
                            // Security Code
                            VStack(alignment: .center, spacing: 16) {
                                Text(NSLocalizedString("security_code", comment: "").uppercased())
                                    .font(.appLabelCaps())
                                    .foregroundColor(.appOnSurfaceVariant)
                                SecurityCodeInput(code: Binding(
                                    get: { group.code ?? "" },
                                    set: { group.code = $0 }
                                ))
                            }
                            .frame(maxWidth: .infinity)

                        }

                        // Phrases
                        VStack(alignment: .leading, spacing: 12) {
                            Text(NSLocalizedString("select_phrases", comment: "").uppercased())
                                .font(.appLabelCaps())
                                .foregroundColor(.appOnSurfaceVariant)

                            if group.phrases != nil {
                                FlowLayout(spacing: 8) {
                                    ForEach(Binding($group.phrases)!) { $phrase in
                                        Button(action: {
                                            if isCreator {
                                                phrase.selected.toggle()
                                            }
                                        }) {
                                            Text(phrase.name)
                                                .font(.appLabelCaps())
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 8)
                                                .background(phrase.selected ? Color.appActiveGreen : Color.appSurfaceContainerHighest)
                                                .foregroundColor(phrase.selected ? Color.appGraniteGray : Color.appOnSurface)
                                                .cornerRadius(AppTheme.cornerRadiusFull)
                                        }
                                    }
                                }
                            }
                        }

                        Spacer(minLength: 40)

                        VStack(spacing: 16) {
                            HStack(spacing: 16) {
                                Button(action: { showingMembers = true }) {
                                    Text(NSLocalizedString("members", comment: ""))
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(AppButtonStyle(variant: .primary))

                                Button(action: {
                                    if isCreator {
                                        showingDeleteAlert = true
                                    } else {
                                        showingLeaveAlert = true
                                    }
                                }) {
                                    Text(isCreator ? NSLocalizedString("delete_group", comment: "") : NSLocalizedString("leave_group", comment: ""))
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(AppButtonStyle(variant: .destructive))
                            }

                            HStack(spacing: 16) {
                                if isCreator {
                                    Button(action: updateGroup) {
                                        Text(NSLocalizedString("update", comment: ""))
                                            .frame(maxWidth: .infinity)
                                    }
                                    .buttonStyle(AppButtonStyle(variant: .primary))
                                    .disabled(!isFormValid)

                                    Button(action: { isPresented = false }) {
                                        Text(NSLocalizedString("cancel", comment: ""))
                                            .frame(maxWidth: .infinity)
                                    }
                                    .buttonStyle(AppButtonStyle(variant: .outline))
                                } else {
                                    Button(action: { isPresented = false }) {
                                        Text(NSLocalizedString("cancel", comment: ""))
                                            .frame(maxWidth: .infinity)
                                    }
                                    .buttonStyle(AppButtonStyle(variant: .outline))
                                }
                            }
                        }
                        .padding(.bottom, 20)
                    }
                    .padding(.horizontal, AppTheme.marginMobile)
                }
            }

            if showingMembers {
                MembersDialog(isPresented: $showingMembers, group: group)
            }
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

    var isFormValid: Bool {
        !group.name.isEmpty &&
        (group.code?.count ?? 0) == 4 &&
        (group.phrases?.contains { $0.selected } ?? false)
    }

    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy"
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
