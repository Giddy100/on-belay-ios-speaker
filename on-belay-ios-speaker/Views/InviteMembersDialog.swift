import SwiftUI

struct InviteMembersDialog: View {
    @Binding var isPresented: Bool
    let group: Group
    var onCancel: () -> Void = {}

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        isPresented = false
                        onCancel()
                    }) {
                        Image(systemName: "arrow.left")
                            .foregroundColor(.appActiveGreen)
                            .font(.title3)
                            .flipsForRightToLeftLayoutDirection(true)
                    }
                    Text(NSLocalizedString("invite_members", comment: ""))
                        .font(.appHeadlineMd())
                        .foregroundColor(.appOnSurface)
                        .padding(.leading, 8)
                    Spacer()
                }
                .padding(.horizontal, AppTheme.marginMobile)
                .padding(.top, 20)
                .padding(.bottom, 24)

                VStack(alignment: .center, spacing: 32) {
                    Text(NSLocalizedString("invite_explanation", comment: ""))
                        .font(.appBodyLg())
                        .foregroundColor(.appOnSurface)
                        .multilineTextAlignment(.center)
                        .padding(.top, 40)

                    VStack(alignment: .leading, spacing: 16) {
                        Text(inviteText)
                            .font(.appBodyLg())
                            .foregroundColor(.appOnSurface)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.appSurfaceContainer)
                            .cornerRadius(AppTheme.cornerRadiusMd)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMd)
                                    .stroke(Color.appOutline.opacity(0.3), lineWidth: 1)
                            )
                    }

                    Button(action: copyToClipboard) {
                        Text(NSLocalizedString("copy", comment: ""))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(AppButtonStyle(variant: .primary))

                    Button(action: {
                        isPresented = false
                        onCancel()
                    }) {
                        Text(NSLocalizedString("close", comment: ""))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(AppButtonStyle(variant: .outline))

                    Spacer()
                }
                .padding(.horizontal, AppTheme.marginMobile)
            }
        }
    }

    private var inviteText: String {
        String(format: NSLocalizedString("invite_template", comment: ""),
               group.name,
               group.groupId,
               group.code ?? "")
    }

    private func copyToClipboard() {
        UIPasteboard.general.string = inviteText
    }
}
