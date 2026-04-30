import SwiftUI

struct MainScreen: View {
    @StateObject var viewModel = MainViewModel()
    @State private var showingCreateGroup = false
    @State private var showingJoinGroup = false
    @State private var showingGroupSettings = false
    @State private var showingMainSettings = false

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                Text(String(format: NSLocalizedString("welcome_user", comment: ""), viewModel.firebase.userSettings?.name ?? ""))
                    .font(.caption)
                    .padding(.horizontal)

                // Group Buttons
                HStack {
                    Button(action: { showingCreateGroup = true }) {
                        Text(NSLocalizedString("create_group", comment: ""))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)

                    Button(action: { showingJoinGroup = true }) {
                        Text(NSLocalizedString("join_group", comment: ""))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.horizontal)

                // Group Dropdown & Settings
                HStack {
                    Picker(NSLocalizedString("settings", comment: ""), selection: $viewModel.selectedGroup) {
                        Text("Select Group").tag(Optional<Group>.none)
                        ForEach(viewModel.firebase.userGroups) { group in
                            Text(group.name).tag(Optional(group))
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity)
                    .onChange(of: viewModel.selectedGroup) { _, newValue in
                        if let group = newValue {
                            viewModel.selectGroup(group)
                        }
                    }

                    Button(action: { showingGroupSettings = true }) {
                        Image(systemName: "gearshape")
                    }
                    .disabled(viewModel.selectedGroup == nil)
                }
                .padding(.horizontal)

                // Active Switch
                Toggle(NSLocalizedString("active", comment: ""), isOn: $viewModel.isActive)
                    .disabled(viewModel.selectedGroup == nil)
                    .onChange(of: viewModel.isActive) { _, _ in
                        viewModel.toggleActive()
                    }
                    .padding(.horizontal)

                // Messages Area
                if viewModel.isActive {
                    ScrollView {
                        VStack(alignment: .leading) {
                            ForEach(viewModel.speech.logs, id: \.self) { log in
                                Text(log)
                                    .font(.system(.body, design: .monospaced))
                                    .padding(.vertical, 2)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxHeight: .infinity)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
                    .padding(.horizontal)
                } else {
                    Spacer()
                }

                // Main Settings Button
                Button(action: { showingMainSettings = true }) {
                    Text(NSLocalizedString("main_settings", comment: ""))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .padding()
            }
            .navigationTitle("Belay is On")
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
}
