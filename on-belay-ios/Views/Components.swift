import SwiftUI

struct SecurityCodeInput: View {
    @Binding var code: String
    let digitCount = 4
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        ZStack {
            // Hidden text field to capture input
            TextField("", text: $code)
                .keyboardType(.numberPad)
                .focused($isTextFieldFocused)
                .opacity(0)
                .onChange(of: code) { _, newValue in
                    if newValue.count > digitCount {
                        code = String(newValue.prefix(digitCount))
                    }
                }

            HStack(spacing: 12) {
                ForEach(0..<digitCount, id: \.self) { index in
                    ZStack {
                        RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMd)
                            .fill(Color.appSurfaceContainerHigh)
                            .frame(width: 64, height: 80)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMd)
                                    .stroke(currentFocusIndex == index && isTextFieldFocused ? Color.appActiveGreen : Color.appOutline, lineWidth: 2)
                            )

                        let digit = digitAt(index)
                        if digit.isEmpty {
                            Circle()
                                .fill(Color.appOutline.opacity(0.3))
                                .frame(width: 12, height: 12)
                        } else {
                            Text(digit)
                                .font(.appStatusCode())
                                .foregroundColor(.appActiveGreen)
                        }
                    }
                    .onTapGesture {
                        isTextFieldFocused = true
                    }
                }
            }
        }
        .onAppear {
            isTextFieldFocused = true
        }
    }

    private var currentFocusIndex: Int {
        min(code.count, digitCount - 1)
    }

    private func digitAt(_ index: Int) -> String {
        if index < code.count {
            let start = code.index(code.startIndex, offsetBy: index)
            return String(code[start])
        }
        return ""
    }
}

struct AppButtonStyle: ButtonStyle {
    let variant: Variant

    enum Variant {
        case primary
        case secondary
        case outline
        case destructive
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.appLabelCaps())
            .padding(.vertical, 12)
            .padding(.horizontal, 24)
            .background(backgroundColor(configuration.isPressed))
            .foregroundColor(foregroundColor())
            .cornerRadius(AppTheme.cornerRadiusFull)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadiusFull)
                    .stroke(borderColor(), lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }

    private func backgroundColor(_ isPressed: Bool) -> Color {
        switch variant {
        case .primary: return Color.appActiveGreen
        case .secondary: return Color.appSurfaceContainerHighest
        case .outline: return Color.clear
        case .destructive: return Color.appError
        }
    }

    private func foregroundColor() -> Color {
        switch variant {
        case .primary: return Color.appGraniteGray
        case .secondary: return Color.appOnSurface
        case .outline: return Color.appOnSurface
        case .destructive: return Color.appOnError
        }
    }

    private func borderColor() -> Color {
        switch variant {
        case .outline: return Color.appOutline
        default: return Color.clear
        }
    }
}

struct AppCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(Color.appSurfaceContainer)
            .cornerRadius(AppTheme.cornerRadiusLg)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLg)
                    .stroke(Color.appOutline.opacity(0.2), lineWidth: 1)
            )
    }
}

extension View {
    func appCard() -> some View {
        self.modifier(AppCard())
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        var totalHeight: CGFloat = 0
        var totalWidth: CGFloat = 0
        var lineWidth: CGFloat = 0
        var lineHeight: CGFloat = 0

        for size in sizes {
            if lineWidth + size.width > (proposal.width ?? 0) {
                totalHeight += lineHeight + spacing
                lineWidth = size.width + spacing
                lineHeight = size.height
            } else {
                lineWidth += size.width + spacing
                lineHeight = max(lineHeight, size.height)
            }
            totalWidth = max(totalWidth, lineWidth)
        }

        return CGSize(width: totalWidth, height: totalHeight + lineHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        var x = bounds.minX
        var y = bounds.minY
        var lineHeight: CGFloat = 0

        for index in subviews.indices {
            if x + sizes[index].width > bounds.maxX {
                x = bounds.minX
                y += lineHeight + spacing
                lineHeight = 0
            }

            subviews[index].place(
                at: CGPoint(x: x, y: y),
                proposal: ProposedViewSize(sizes[index])
            )

            x += sizes[index].width + spacing
            lineHeight = max(lineHeight, sizes[index].height)
        }
    }
}
