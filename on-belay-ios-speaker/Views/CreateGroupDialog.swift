import SwiftUI
import FirebaseAuth

struct CreateGroupDialog: View {
    @Binding var isPresented: Bool
    @State private var name = ""
    @State private var code = ""
    @State private var phrases: [Phrase] = []
    @State private var createdGroup: Group?
    @State private var showingInvite = false

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
                    Text(NSLocalizedString("create_group", comment: ""))
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
                        // Name Input
                        VStack(alignment: .leading, spacing: 8) {
                            Text(NSLocalizedString("name", comment: "").uppercased())
                                .font(.appLabelCaps())
                                .foregroundColor(.appOnSurfaceVariant)
                            TextField("", text: $name)
                                .font(.appBodyLg())
                                .foregroundColor(.appOnSurface)
                                .padding()
                                .background(Color.appSurfaceContainer)
                                .cornerRadius(AppTheme.cornerRadiusMd)
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMd)
                                        .stroke(Color.appOutline.opacity(0.3), lineWidth: 1)
                                )
                        }

                        // Security Code Input
                        VStack(alignment: .center, spacing: 16) {
                            Text(NSLocalizedString("security_code", comment: "").uppercased())
                                .font(.appLabelCaps())
                                .foregroundColor(.appOnSurfaceVariant)
                            SecurityCodeInput(code: $code)
                        }
                        .frame(maxWidth: .infinity)

                        // Phrases
                        VStack(alignment: .leading, spacing: 12) {
                            Text(NSLocalizedString("select_phrases", comment: "").uppercased())
                                .font(.appLabelCaps())
                                .foregroundColor(.appOnSurfaceVariant)

                            FlowLayout(spacing: 8) {
                                ForEach($phrases) { $phrase in
                                    Button(action: { phrase.selected.toggle() }) {
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

                        Spacer(minLength: 40)

                        Button(action: createGroup) {
                            Text(NSLocalizedString("create", comment: ""))
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(AppButtonStyle(variant: .primary))
                        .disabled(!isFormValid)
                        .padding(.bottom, 20)
                    }
                    .padding(.horizontal, AppTheme.marginMobile)
                }
            }

            if showingInvite, let group = createdGroup {
                InviteMembersDialog(isPresented: $showingInvite, group: group) {
                    isPresented = false
                }
            }
        }
        .task {
            phrases = await FirebaseService.shared.getDefaultPhrases()
        }
    }

    var isFormValid: Bool {
        !name.isEmpty &&
        code.count == 4 &&
        phrases.contains { $0.selected }
    }

    func createGroup() {
        let group = Group(
            groupId: UUID().uuidString,
            name: name,
            createdByName: FirebaseService.shared.userSettings?.name ?? "",
            code: code,
            startDate: nil,
            endDate: nil,
            phrases: phrases,
            createdByUid: FirebaseService.shared.currentUser?.uid ?? "",
            joinedUsers: []
        )
        Task {
            if await FirebaseService.shared.createGroup(group) {
                createdGroup = group
                showingInvite = true
            }
        }
    }
}
