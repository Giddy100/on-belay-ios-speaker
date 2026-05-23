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

                                Text(formatDate(startDate))
                                    .font(.appBodyLg())
                                    .foregroundColor(.appActiveGreen)
                                    .overlay(
                                        DatePicker("", selection: $startDate, displayedComponents: .date)
                                            .labelsHidden()
                                            .accentColor(.appActiveGreen)
                                            .opacity(0.011)
                                    )
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 8) {
                                Text(NSLocalizedString("end_date", comment: "").uppercased())
                                    .font(.appLabelCaps())
                                    .foregroundColor(.appOnSurfaceVariant)

                                Text(formatDate(endDate))
                                    .font(.appBodyLg())
                                    .foregroundColor(.appActiveGreen)
                                    .overlay(
                                        DatePicker("", selection: $endDate, displayedComponents: .date)
                                            .labelsHidden()
                                            .accentColor(.appActiveGreen)
                                            .opacity(0.011)
                                    )
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

                            FlowLayout(spacing: 8) {
                                ForEach($phrases) { $phrase in
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
                        }

                        Spacer(minLength: 40)

                        Button(action: createGroup) {
                            Text(NSLocalizedString("create", comment: ""))
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(AppButtonStyle(variant: .primary))
                        .disabled(!isFormValid)
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
        return diff >= 0 && diff <= 30 * 24 * 60 * 60
    }

    var isFormValid: Bool {
        !name.isEmpty &&
        code.count == 4 &&
        isDateRangeValid &&
        phrases.contains { $0.selected }
    }

    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy"
        return formatter.string(from: date)
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
