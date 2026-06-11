import SwiftUI

struct MainScreen: View {
    @StateObject var viewModel = MainViewModel()
    @State private var showingMainSettings = false

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: AppTheme.gutter) {
                // 1st Row: Top bar (Belay is On Speaker)
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
                    }

                    // Main Toggle Button (Synchronize with Main)
                    Button(action: {
                        viewModel.syncWithMain()
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                            Text(NSLocalizedString("synchronize_with_main", comment: ""))
                        }
                        .font(.appLabelCaps())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.appActiveGreen)
                        .foregroundColor(.appGraniteGray)
                        .cornerRadius(AppTheme.cornerRadiusLg)
                        .shadow(color: Color.appActiveGreen.opacity(0.3), radius: 8)
                    }
                }
                .appCard()
                .padding(.horizontal, AppTheme.marginMobile)

                Spacer()
            }
        }
        .sheet(isPresented: $showingMainSettings) {
            MainSettingsDialog(isPresented: $showingMainSettings)
        }
    }
}
