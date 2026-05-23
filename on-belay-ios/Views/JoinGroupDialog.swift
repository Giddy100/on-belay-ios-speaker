import SwiftUI

struct JoinGroupDialog: View {
    @Binding var isPresented: Bool
    @State private var searchQuery = ""
    @State private var searchResults: [Group] = []
    @State private var selectedGroup: Group?
    @State private var showingCodeEntry = false
    @State private var isSearching = false

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
                    }
                    Text(NSLocalizedString("join_group", comment: ""))
                        .font(.appHeadlineMd())
                        .foregroundColor(.appOnSurface)
                        .padding(.leading, 8)
                    Spacer()
                }
                .padding(.horizontal, AppTheme.marginMobile)
                .padding(.top, 20)
                .padding(.bottom, 24)

                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.appActiveGreen)
                    TextField(NSLocalizedString("name", comment: ""), text: $searchQuery)
                        .font(.appBodyLg())
                        .foregroundColor(.appOnSurface)
                        .onChange(of: searchQuery) { _, newValue in
                            if newValue.count >= 2 {
                                search()
                            } else {
                                searchResults = []
                            }
                        }
                }
                .padding()
                .background(Color.appSurfaceContainer)
                .cornerRadius(AppTheme.cornerRadiusMd)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMd)
                        .stroke(Color.appOutline.opacity(0.3), lineWidth: 1)
                )
                .padding(.horizontal, AppTheme.marginMobile)

                if isSearching {
                    Text(NSLocalizedString("searching_active_signals", comment: ""))
                        .font(.appLabelCaps())
                        .foregroundColor(.appOnSurfaceVariant)
                        .padding(.top, 20)
                } else if !searchQuery.isEmpty {
                    Text(String(format: NSLocalizedString("results_for", comment: ""), searchQuery.uppercased()))
                        .font(.appLabelCaps())
                        .foregroundColor(.appActiveGreen)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 24)
                        .padding(.horizontal, AppTheme.marginMobile)
                }

                // Results
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(searchResults) { group in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(group.name)
                                        .font(.appHeadlineMd())
                                        .foregroundColor(.appOnSurface)
                                    Text(String(format: NSLocalizedString("by_author", comment: ""), group.createdByName))
                                        .font(.appBodySm())
                                        .foregroundColor(.appOnSurfaceVariant)
                                }
                                Spacer()
                                Button(NSLocalizedString("join", comment: "").uppercased()) {
                                    selectedGroup = group
                                    showingCodeEntry = true
                                }
                                .buttonStyle(AppButtonStyle(variant: .primary))
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
                    .padding(.top, 16)
                    .padding(.horizontal, AppTheme.marginMobile)
                }

                Spacer()
            }

            if showingCodeEntry, let group = selectedGroup {
                Color.black.opacity(0.6).ignoresSafeArea()
                    .onTapGesture { showingCodeEntry = false }

                CodeEntryDialog(isPresented: $showingCodeEntry, groupName: group.name) { code in
                    join(code: code)
                }
            }
        }
    }

    func search() {
        isSearching = true
        Task {
            searchResults = await FirebaseService.shared.searchGroups(query: searchQuery)
            isSearching = false
        }
    }

    func join(code: String) {
        guard let group = selectedGroup else { return }
        Task {
            if await FirebaseService.shared.joinGroup(groupId: group.groupId, code: code) {
                isPresented = false
            }
        }
    }
}

struct CodeEntryDialog: View {
    @Binding var isPresented: Bool
    let groupName: String
    var onJoin: (String) -> Void
    @State private var code = ""

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "lock.fill")
                .font(.system(size: 40))
                .foregroundColor(.appActiveGreen)

            Text(NSLocalizedString("security_code", comment: ""))
                .font(.appHeadlineMd())
                .foregroundColor(.appOnSurface)

            Text(String(format: NSLocalizedString("enter_security_code_desc", comment: ""), groupName))
                .font(.appBodySm())
                .foregroundColor(.appOnSurfaceVariant)
                .multilineTextAlignment(.center)

            SecurityCodeInput(code: $code)
                .padding(.vertical, 8)

            VStack(spacing: 12) {
                Button(NSLocalizedString("confirm", comment: "")) {
                    onJoin(code)
                }
                .buttonStyle(AppButtonStyle(variant: .primary))
                .disabled(code.count != 4)
                .frame(maxWidth: .infinity)

                Button(NSLocalizedString("cancel", comment: "")) {
                    isPresented = false
                }
                .buttonStyle(AppButtonStyle(variant: .outline))
                .frame(maxWidth: .infinity)
            }
        }
        .padding(AppTheme.containerPadding)
        .background(Color.appSurfaceContainer)
        .cornerRadius(AppTheme.cornerRadiusLg)
        .padding(32)
    }
}
