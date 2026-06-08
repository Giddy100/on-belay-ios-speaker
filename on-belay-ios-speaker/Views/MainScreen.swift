import SwiftUI

struct MainScreen: View {
    @StateObject var viewModel = MainViewModel()
    @State private var showingCreateGroup = false
    @State private var showingJoinGroup = false
    @State private var showingGroupSettings = false
    @State private var showingMainSettings = false
    @State private var showingSwitchGroup = false
    @State private var showingQuickSend = false
    @State private var showingHelp = false

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: AppTheme.gutter) {
                // 1st Row: Top bar (Belay is On)
                HStack {
                    HStack(spacing: 12) {
                        Image("BelayIsOnLogo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 36, height: 36)
                            .cornerRadius(16)
                        Text(NSLocalizedString("app_name", comment: "").uppercased())
                            .font(.appHeadlineMd())
                            .foregroundColor(.appActiveGreen)
                    }
                    Spacer()
                    Button(action: { showingMainSettings = true }) {
                        Image(systemName: "gearshape")
                            .font(.title2)
                            .foregroundColor(.appActiveGreen)
                    }
                }
                .padding(.horizontal, AppTheme.marginMobile)
                .padding(.top, 8)

                Divider()
                    .background(Color.appOutline.opacity(0.2))

                // 2nd Row: Logged in as
                HStack(spacing: 4) {
                    Text(NSLocalizedString("logged_in_as", comment: ""))
                        .font(.appLabelCaps())
                        .foregroundColor(.appOnSurfaceVariant)
                    Text(viewModel.firebase.userSettings?.name ?? "")
                        .font(.appLabelCaps())
                        .fontWeight(.bold)
                        .foregroundColor(.appOnSurface)
                    Spacer()
                }
                .padding(.horizontal, AppTheme.marginMobile)

                // 3rd Row: LIVE MONITOR (Transcript)
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color.appActiveGreen)
                                .frame(width: 8, height: 8)
                                .shadow(color: Color.appActiveGreen.opacity(0.5), radius: 4)
                            Text(NSLocalizedString("live_monitor", comment: ""))
                                .font(.appLabelCaps())
                                .foregroundColor(.appActiveGreen)
                        }
                        Spacer()
                        if !viewModel.selectedGroupId.isEmpty {
                            if viewModel.isActive {
                                Button(action: { showingQuickSend = true }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "paperplane")
                                        Text(NSLocalizedString("quick_send", comment: ""))
                                    }
                                    .font(.appLabelCaps())
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: AppTheme.cornerRadiusFull)
                                            .stroke(Color.appActiveGreen, lineWidth: 1)
                                    )
                                    .foregroundColor(.appActiveGreen)
                                }
                            } else {
                                Button(action: { showingHelp = true }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "questionmark.circle")
                                        Text(NSLocalizedString("help", comment: ""))
                                    }
                                    .font(.appLabelCaps())
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: AppTheme.cornerRadiusFull)
                                            .stroke(Color.appActiveGreen, lineWidth: 1)
                                    )
                                    .foregroundColor(.appActiveGreen)
                                }
                            }
                        }
                    }

                    // The Transcript Area with "Inner Frame"
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(viewModel.speech.logs.indices, id: \.self) { index in
                                    let log = viewModel.speech.logs[index]
                                    HStack(alignment: .top, spacing: 4) {
                                        Text(log.hasPrefix(">>") ? ">>" : ">")
                                            .foregroundColor(log.hasPrefix(">>") ? .appActiveGreen : .appOnSurfaceVariant)
                                        Text(log.replacingOccurrences(of: ">>", with: "").replacingOccurrences(of: ">", with: ""))
                                            .foregroundColor(log.hasPrefix(">>") ? .appActiveGreen : .appOnSurface)
                                    }
                                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .id(index)
                                }
                            }
                            .padding(16)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 300) // Much higher as requested
                        .background(Color.appSurfaceContainerLowest) // Darker "Inner Frame"
                        .cornerRadius(AppTheme.cornerRadiusMd)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMd)
                                .stroke(Color.appOutline.opacity(0.1), lineWidth: 1)
                        )
                        .onChange(of: viewModel.speech.logs.count) {
                            if let lastIndex = viewModel.speech.logs.indices.last {
                                withAnimation {
                                    proxy.scrollTo(lastIndex, anchor: .bottom)
                                }
                            }
                        }
                    }
                }
                .appCard()
                .padding(.horizontal, AppTheme.marginMobile)

                // 4th Row: ACTIVE GROUP
                VStack(alignment: .leading, spacing: AppTheme.gutter) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(NSLocalizedString("active_group", comment: "").uppercased())
                                .font(.appLabelCaps())
                                .foregroundColor(.appActiveGreen)
                            Text(viewModel.selectedGroup?.name ?? NSLocalizedString("select_group", comment: ""))
                                .font(.appHeadlineMd())
                                .foregroundColor(.appOnSurface)
                        }
                        Spacer()
                        HStack(spacing: 12) {
                            Button(action: { showingGroupSettings = true }) {
                                Image(systemName: "slider.horizontal.3")
                                    .padding(10)
                                    .background(Color.appSurfaceContainerHigh)
                                    .cornerRadius(AppTheme.cornerRadiusMd)
                                    .foregroundColor(.appOnSurfaceVariant)
                            }
                            .disabled(viewModel.selectedGroupId.isEmpty)

                            Button(action: { showingSwitchGroup = true }) {
                                Image(systemName: "arrow.left.arrow.right")
                                    .padding(10)
                                    .background(Color.appSurfaceContainerHigh)
                                    .cornerRadius(AppTheme.cornerRadiusMd)
                                    .foregroundColor(.appOnSurfaceVariant)
                            }
                        }
                    }

                    // Main Toggle Button (Activate Session)
                    Button(action: {
                        viewModel.isActive.toggle()
                        viewModel.activeToggled()
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: viewModel.isActive ? "mic.slash.fill" : "mic.fill")
                            Text(NSLocalizedString(viewModel.isActive ? "deactivate_session" : "activate_session", comment: ""))
                        }
                        .font(.appLabelCaps())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(viewModel.isActive ? Color.appSafetyOrange : Color.appActiveGreen)
                        .foregroundColor(viewModel.isActive ? .white : .appGraniteGray)
                        .cornerRadius(AppTheme.cornerRadiusLg)
                        .shadow(color: (viewModel.isActive ? Color.appSafetyOrange : Color.appActiveGreen).opacity(0.3), radius: 8)
                    }
                    .disabled(viewModel.selectedGroupId.isEmpty)
                    .opacity(viewModel.selectedGroupId.isEmpty ? 0.5 : 1.0)
                }
                .appCard()
                .padding(.horizontal, AppTheme.marginMobile)

                Spacer()

                // Join/Create Footer
                HStack(spacing: 12) {
                    Button(action: { showingCreateGroup = true }) {
                        Label(NSLocalizedString("create", comment: ""), systemImage: "plus")
                            .font(.appLabelCaps())
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(AppButtonStyle(variant: .outline))

                    Button(action: { showingJoinGroup = true }) {
                        Label(NSLocalizedString("join", comment: ""), systemImage: "arrow.right.to.line")
                            .font(.appLabelCaps())
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

            if showingQuickSend, let group = viewModel.selectedGroup {
                QuickSendDialog(isPresented: $showingQuickSend, group: group)
                    .transition(.move(edge: .bottom))
                    .zIndex(1)
            }

            if showingHelp {
                HelpDialog(isPresented: $showingHelp)
                    .transition(.move(edge: .bottom))
                    .zIndex(1)
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
