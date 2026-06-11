import SwiftUI

struct MainSettingsDialog: View {
    @Binding var isPresented: Bool

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

                VStack(alignment: .leading, spacing: 32) {
                    // Danger Zone
                    VStack(alignment: .leading, spacing: 16) {
                        Button(action: switchUser) {
                            Text(NSLocalizedString("switch_user", comment: ""))
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(AppButtonStyle(variant: .destructive))
                    }

                    Spacer()
                }
                .padding(.horizontal, AppTheme.marginMobile)
            }
        }
    }

    func switchUser() {
        FirebaseService.shared.signOut()
        isPresented = false
    }
}
