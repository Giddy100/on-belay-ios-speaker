import SwiftUI
import FirebaseAuth

struct CreateGroupDialog: View {
    @Binding var isPresented: Bool
    @State private var name = ""
    @State private var code = ""
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(7 * 24 * 60 * 60)
    @State private var phrases: [Phrase] = []

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
                    }
                    Text(NSLocalizedString("create_group", comment: ""))
                        .font(.appHeadlineMd())
                        .foregroundColor(.appOnSurface)
                        .padding(.leading, 8)
                    Spacer()
                }
                .padding(.horizontal, AppTheme.marginMobile)
                .padding(.top, 20)
                .padding(.bottom, 24)

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Name Input
                        VStack(alignment: .leading, spacing: 8) {
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

                        // Security Code Input
                        VStack(alignment: .center, spacing: 16) {
                            Text(NSLocalizedString("security_code", comment: "").uppercased())
                                .font(.appLabelCaps())
                                .foregroundColor(.appOnSurfaceVariant)
                            SecurityCodeInput(code: $code)
                        }
                        .frame(maxWidth: .infinity)

                        // Dates
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(NSLocalizedString("start_date", comment: "").uppercased())
                                    .font(.appLabelCaps())
                                    .foregroundColor(.appOnSurfaceVariant)
                                DatePicker("", selection: $startDate, displayedComponents: .date)
                                    .labelsHidden()
                                    .accentColor(.appActiveGreen)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 8) {
                                Text(NSLocalizedString("end_date", comment: "").uppercased())
                                    .font(.appLabelCaps())
                                    .foregroundColor(.appOnSurfaceVariant)
                                DatePicker("", selection: $endDate, displayedComponents: .date)
                                    .labelsHidden()
                                    .accentColor(.appActiveGreen)
                            }
                        }
                        .padding()
                        .background(Color.appSurfaceContainer)
                        .cornerRadius(AppTheme.cornerRadiusMd)

                        // Phrases
                        VStack(alignment: .leading, spacing: 12) {
                            Text(NSLocalizedString("select_phrases", comment: "").uppercased())
                                .font(.appLabelCaps())
                                .foregroundColor(.appOnSurfaceVariant)

                            FlowLayout(items: $phrases) { $phrase in
                                Button(action: { phrase.selected.toggle() }) {
                                    Text(phrase.name)
                                        .font(.appLabelCaps())
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(phrase.selected ? Color.appActiveGreen : Color.appSurfaceContainerHighest)
                                        .foregroundColor(phrase.selected ? Color.appGraniteGray : Color.appOnSurface)
                                        .cornerRadius(AppTheme.cornerRadiusFull)
                                }
                            }
                        }

                        Spacer(minLength: 40)

                        Button(action: createGroup) {
                            Text(NSLocalizedString("create", comment: ""))
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(AppButtonStyle(variant: .primary))
                        .disabled(name.isEmpty || code.count != 4 || !isDateRangeValid)
                        .padding(.bottom, 20)
                    }
                    .padding(.horizontal, AppTheme.marginMobile)
                }
            }
        }
        .task {
            phrases = await FirebaseService.shared.getDefaultPhrases()
        }
    }

    var isDateRangeValid: Bool {
        let diff = endDate.timeIntervalSince(startDate)
        return diff > 0 && diff <= 30 * 24 * 60 * 60
    }

    func createGroup() {
        let group = Group(
            groupId: UUID().uuidString,
            name: name,
            createdByName: FirebaseService.shared.userSettings?.name ?? "",
            code: code,
            startDate: startDate.timeIntervalSince1970 * 1000,
            endDate: endDate.timeIntervalSince1970 * 1000,
            phrases: phrases,
            createdByUid: FirebaseService.shared.currentUser?.uid ?? "",
            joinedUsers: []
        )
        Task {
            if await FirebaseService.shared.createGroup(group) {
                isPresented = false
            }
        }
    }
}

struct FlowLayout: View {
    @Binding var items: [Phrase]
    let content: (Binding<Phrase>) -> AnyView

    init<V: View>(items: Binding<[Phrase]>, @ViewBuilder content: @escaping (Binding<Phrase>) -> V) {
        self._items = items
        self.content = { Binding<Phrase> in AnyView(content(Binding<Phrase>)) }
    }

    var body: some View {
        var width = CGFloat.zero
        var height = CGFloat.zero

        return GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                ForEach(items.indices, id: \.self) { index in
                    content($items[index])
                        .padding([.horizontal, .vertical], 4)
                        .alignmentGuide(.leading) { d in
                            if (abs(width - d.width) > geo.size.width) {
                                width = 0
                                height -= d.height
                            }
                            let result = width
                            if index == items.count - 1 {
                                width = 0
                            } else {
                                width -= d.width
                            }
                            return result
                        }
                        .alignmentGuide(.top) { d in
                            let result = height
                            if index == items.count - 1 {
                                height = 0
                            }
                            return result
                        }
                }
            }
        }
        .frame(minHeight: 150) // Adjust as needed
    }
}
