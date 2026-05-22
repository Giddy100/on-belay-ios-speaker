import SwiftUI

struct MainScreen: View {
    @StateObject var viewModel = MainViewModel()
    @State private var showingCreateGroup = false
    @State private var showingJoinGroup = false
    @State private var showingGroupSettings = false
    @State private var showingMainSettings = false
    @State private var showingSwitchGroup = false

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: AppTheme.gutter) {
                // Top bar
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(String(format: NSLocalizedString("welcome_user", comment: ""), viewModel.firebase.userSettings?.name ?? ""))
                            .font(.appBodySm())
                            .foregroundColor(.appOnSurfaceVariant)
                        Text(NSLocalizedString("app_name", comment: ""))
                            .font(.appHeadlineMd())
                            .foregroundColor(.appOnSurface)
                    }
                    Spacer()
                    Button(action: { showingMainSettings = true }) {
                        Image(systemName: "gearshape.fill")
                            .font(.title2)
                            .foregroundColor(.appOnSurface)
                    }
                }
                .padding(.horizontal, AppTheme.marginMobile)
                .padding(.top, 8)

                // Group Selector Card
                Button(action: { showingSwitchGroup = true }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(NSLocalizedString("select_group", comment: "").uppercased())
                                .font(.appLabelCaps())
                                .foregroundColor(.appActiveGreen)
                            Text(viewModel.selectedGroup?.name ?? NSLocalizedString("select_group", comment: ""))
                                .font(.appBodyLg())
                                .foregroundColor(.appOnSurface)
                        }
                        Spacer()
                        Image(systemName: "chevron.down")
                            .foregroundColor(.appOnSurfaceVariant)
                    }
                    .appCard()
                }
                .padding(.horizontal, AppTheme.marginMobile)

                // Quick Send Section
                if viewModel.isActive {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(NSLocalizedString("quick_send", comment: ""))
                            .font(.appLabelCaps())
                            .foregroundColor(.appOnSurfaceVariant)

                        HStack {
                            // Placeholder buttons for now as per instruction
                            Button("ON BELAY") { }
                                .buttonStyle(AppButtonStyle(variant: .secondary))
                            Button("CLIMBING") { }
                                .buttonStyle(AppButtonStyle(variant: .secondary))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, AppTheme.marginMobile)
                }

                // Main Toggle Button
                Spacer()

                Button(action: {
                    viewModel.isActive.toggle()
                    viewModel.activeToggled()
                }) {
                    ZStack {
                        Circle()
                            .fill(viewModel.isActive ? Color.appSafetyOrange : Color.appActiveGreen)
                            .frame(width: 200, height: 200)
                            .shadow(color: (viewModel.isActive ? Color.appSafetyOrange : Color.appActiveGreen).opacity(0.3), radius: 20)

                        Text(viewModel.isActive ? NSLocalizedString("stop_listening", comment: "") : NSLocalizedString("start_listening", comment: ""))
                            .font(.appLabelCaps())
                            .foregroundColor(viewModel.isActive ? .white : .appGraniteGray)
                            .multilineTextAlignment(.center)
                            .frame(width: 120)
                    }
                }
                .disabled(viewModel.selectedGroupId.isEmpty)
                .opacity(viewModel.selectedGroupId.isEmpty ? 0.5 : 1.0)

                Spacer()

                // Transcript Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(NSLocalizedString("transcript", comment: ""))
                            .font(.appLabelCaps())
                            .foregroundColor(.appOnSurfaceVariant)
                        Spacer()
                        if !viewModel.selectedGroupId.isEmpty {
                            Button(action: { showingGroupSettings = true }) {
                                Image(systemName: "info.circle")
                                    .foregroundColor(.appOnSurfaceVariant)
                            }
                        }
                    }

                    ScrollView {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(viewModel.speech.logs.indices, id: \.self) { index in
                                Text(viewModel.speech.logs[index])
                                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                                    .foregroundColor(.appOnSurface)
                                    .padding(.vertical, 4)
                                    .padding(.horizontal, 12)
                                    .background(Color.appSurfaceContainerHighest.opacity(0.5))
                                    .cornerRadius(AppTheme.cornerRadiusSm)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(height: 120)
                    .padding(8)
                    .background(Color.appSurfaceContainerLow)
                    .cornerRadius(AppTheme.cornerRadiusMd)
                }
                .padding(.horizontal, AppTheme.marginMobile)
                .padding(.bottom, 20)

                // Join/Create Footer
                HStack(spacing: 12) {
                    Button(action: { showingCreateGroup = true }) {
                        Label(NSLocalizedString("create", comment: ""), systemImage: "plus")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(AppButtonStyle(variant: .outline))

                    Button(action: { showingJoinGroup = true }) {
                        Label(NSLocalizedString("join", comment: ""), systemImage: "magnifyingglass")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(AppButtonStyle(variant: .outline))
                }
                .padding(.horizontal, AppTheme.marginMobile)
                .padding(.bottom, AppTheme.containerPadding)
            }

            if showingSwitchGroup {
                Color.black.opacity(0.5).ignoresSafeArea()
                    .onTapGesture { showingSwitchGroup = false }
                SwitchGroupDialog(viewModel: viewModel, isPresented: $showingSwitchGroup)
            }
        }
        .sheet(isPresented: $showingCreateGroup) {
            CreateGroupDialog(isPresented: $showingCreateGroup)
        }
        .sheet(isPresented: $showingJoinGroup) {
            JoinGroupDialog(isPresented: $showingJoinGroup)
        }
        .sheet(isPresented: $showingGroupSettings) {
            if let group = viewModel.selectedGroup {
                GroupSettingsDialog(isPresented: $showingGroupSettings, group: group)
            }
        }
        .sheet(isPresented: $showingMainSettings) {
            MainSettingsDialog(isPresented: $showingMainSettings)
        }
    }
}
