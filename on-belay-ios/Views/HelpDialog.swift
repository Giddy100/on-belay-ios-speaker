import SwiftUI

struct HelpDialog: View {
    @Binding var isPresented: Bool

    var body: some View {
        ZStack {
            Color.appBackground.opacity(0.4).ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 20) {
                    Capsule()
                        .fill(Color.appOutline.opacity(0.3))
                        .frame(width: 40, height: 4)
                        .padding(.top, 12)

                    Text(NSLocalizedString("help_title", comment: ""))
                        .font(.appHeadlineMd())
                        .foregroundColor(.appOnSurface)
                        .padding(.top, 8)

                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            ForEach(1...6, id: \.self) { index in
                                Text(NSLocalizedString("help_content_\(index)", comment: ""))
                                    .font(.appBodySm())
                                    .foregroundColor(.appOnSurface)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .padding(.horizontal, AppTheme.marginMobile)
                    }
                    .frame(maxHeight: 500)

                    Button(action: { isPresented = false }) {
                        Text(NSLocalizedString("close", comment: "").uppercased())
                            .font(.appLabelCaps())
                            .foregroundColor(.appOnSurface)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.appSurfaceContainerHighest)
                            .cornerRadius(AppTheme.cornerRadiusMd)
                    }
                    .padding(.horizontal, AppTheme.marginMobile)
                    .padding(.bottom, 24)
                }
                .background(Color.appSurfaceContainer)
                .cornerRadius(AppTheme.cornerRadiusXl, corners: [.topLeft, .topRight])
            }
            .ignoresSafeArea(edges: .bottom)
        }
    }
}
