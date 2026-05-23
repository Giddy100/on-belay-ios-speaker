import SwiftUI

struct QuickSendDialog: View {
    @Binding var isPresented: Bool
    let group: Group

    var selectedPhrases: [Phrase] {
        group.phrases?.filter { $0.selected } ?? []
    }

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

                    Text(NSLocalizedString("quick_send_command", comment: ""))
                        .font(.appHeadlineMd())
                        .foregroundColor(.appOnSurface)
                        .padding(.top, 8)

                    ScrollView {
                        VStack(spacing: 12) {
                            let phrases = selectedPhrases
                            ForEach(0..<phrases.count, id: \.self) { index in
                                let phrase = phrases[index]
                                Button(action: {
                                    sendPhrase(phrase)
                                }) {
                                    Text(phrase.name)
                                        .font(.appHeadlineMd())
                                        .italic()
                                        .foregroundColor(index == 0 ? Color.appGraniteGray : .white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 16)
                                        .background(index == 0 ? Color.appActiveGreen : Color.appSurfaceContainerHighest)
                                        .cornerRadius(AppTheme.cornerRadiusMd)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMd)
                                                .stroke(index == 0 ? Color.clear : Color.appOutline.opacity(0.2), lineWidth: 1)
                                        )
                                }
                            }
                        }
                        .padding(.horizontal, AppTheme.marginMobile)
                    }
                    .frame(maxHeight: 400)

                    Button(action: { isPresented = false }) {
                        Text(NSLocalizedString("cancel", comment: "").uppercased())
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

    private func sendPhrase(_ phrase: Phrase) {
        Task {
            await FirebaseService.shared.notifyGroupMembers(groupId: group.groupId, phraseId: phrase.phraseId)
            isPresented = false
        }
    }
}

// Helper to support specific corners rounding
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape( RoundedCorner(radius: radius, corners: corners) )
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
