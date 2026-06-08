import SwiftUI

struct MainSettingsDialog: View {
    @Binding var isPresented: Bool
    @State private var name = FirebaseService.shared.userSettings?.name ?? ""
    @State private var volume = FirebaseService.shared.userSettings?.volume ?? 1.0

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
                    Text(NSLocalizedString("main_settings", comment: ""))
                        .font(.appHeadlineMd())
                        .foregroundColor(.appOnSurface)
                        .padding(.leading, 8)
                    Spacer()
                }
                .padding(.horizontal, AppTheme.marginMobile)
                .padding(.top, 20)
                .padding(.bottom, 24)

                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {
                        // Profile Section
                        VStack(alignment: .leading, spacing: 16) {
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

                        // Audio Section
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text(NSLocalizedString("volume", comment: "").uppercased())
                                    .font(.appLabelCaps())
                                    .foregroundColor(.appOnSurfaceVariant)
                                Spacer()
                                Text("\(Int(volume * 100))%")
                                    .font(.appLabelCaps())
                                    .foregroundColor(.appActiveGreen)
                            }

                            HStack(spacing: 16) {
                                Image(systemName: "speaker.fill")
                                    .foregroundColor(.appOnSurfaceVariant)
                                Slider(value: $volume, in: 0...1)
                                    .accentColor(.appActiveGreen)
                                Image(systemName: "speaker.wave.3.fill")
                                    .foregroundColor(.appOnSurfaceVariant)
                            }
                            .padding()
                            .background(Color.appSurfaceContainer)
                            .cornerRadius(AppTheme.cornerRadiusMd)
                        }

                        // Danger Zone
                        VStack(alignment: .leading, spacing: 16) {
                            Button(action: switchUser) {
                                Text(NSLocalizedString("switch_user", comment: ""))
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(AppButtonStyle(variant: .destructive))
                        }

                        Spacer(minLength: 40)

                        Button(action: saveSettings) {
                            Text(NSLocalizedString("save", comment: ""))
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(AppButtonStyle(variant: .primary))
                        .disabled(name.isEmpty)
                        .padding(.bottom, 20)
                    }
                    .padding(.horizontal, AppTheme.marginMobile)
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
