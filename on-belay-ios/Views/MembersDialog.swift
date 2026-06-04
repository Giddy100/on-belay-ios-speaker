import SwiftUI

struct MembersDialog: View {
    @Binding var isPresented: Bool
    let group: Group
    @State private var members: [GroupMember] = []
    @State private var isLoading = false
    @State private var memberToRemove: GroupMember?
    @State private var showingRemoveAlert = false
    @State private var showingInvite = false

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
                    Text(NSLocalizedString("members", comment: "").uppercased())
                        .font(.appHeadlineMd())
                        .foregroundColor(.appOnSurface)
                        .padding(.leading, 8)
                    Spacer()
                }
                .padding(.horizontal, AppTheme.marginMobile)
                .padding(.top, 20)
                .padding(.bottom, 24)

                if isLoading {
                    Spacer()
                    ProgressView()
                        .tint(.appActiveGreen)
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(members) { member in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(member.name)
                                            .font(.appHeadlineMd())
                                            .foregroundColor(.appOnSurface)
                                        HStack(spacing: 4) {
                                            Text(NSLocalizedString("active", comment: ""))
                                                .font(.appBodySm())
                                                .foregroundColor(.appOnSurfaceVariant)
                                            if member.active {
                                                Image(systemName: "checkmark")
                                                    .foregroundColor(.appActiveGreen)
                                                    .font(.caption)
                                            }
                                        }
                                    }
                                    Spacer()
                                    if isCreator && member.id != group.createdByUid {
                                        Button(action: {
                                            memberToRemove = member
                                            showingRemoveAlert = true
                                        }) {
                                            Text(NSLocalizedString("remove", comment: ""))
                                        }
                                        .buttonStyle(AppButtonStyle(variant: .destructive))
                                    }
                                }
                                .padding()
                                .background(Color.appSurfaceContainer)
                                .cornerRadius(AppTheme.cornerRadiusMd)
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMd)
                                        .stroke(Color.appOutline.opacity(0.1), lineWidth: 1)
                                )
                            }
                        }
                        .padding(.horizontal, AppTheme.marginMobile)
                    }
                }

                VStack(spacing: 12) {
                    Button(action: { showingInvite = true }) {
                        Text(NSLocalizedString("invite_members", comment: ""))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(AppButtonStyle(variant: .primary))

                    Button(action: { isPresented = false }) {
                        Text(NSLocalizedString("cancel", comment: ""))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(AppButtonStyle(variant: .outline))
                }
                .padding(.horizontal, AppTheme.marginMobile)
                .padding(.vertical, 24)
            }

            if showingInvite {
                InviteMembersDialog(isPresented: $showingInvite, group: group)
            }
        }
        .task {
            await loadMembers()
        }
        .alert(String(format: NSLocalizedString("confirm_remove_member", comment: ""), memberToRemove?.name ?? ""), isPresented: $showingRemoveAlert) {
            Button(NSLocalizedString("yes", comment: ""), role: .destructive) {
                if let member = memberToRemove {
                    removeMember(member)
                }
            }
            Button(NSLocalizedString("no", comment: ""), role: .cancel) {}
        }
    }

    func loadMembers() async {
        isLoading = true
        members = await FirebaseService.shared.getGroupMembers(groupId: group.groupId)
        isLoading = false
    }

    func removeMember(_ member: GroupMember) {
        Task {
            if await FirebaseService.shared.removeGroupMember(groupId: group.groupId, userId: member.id) {
                await loadMembers()
            }
        }
    }
}
