import SwiftUI

struct SwitchGroupDialog: View {
    @ObservedObject var viewModel: MainViewModel
    @Binding var isPresented: Bool

    var body: some View {
        VStack(spacing: 20) {
            Text(NSLocalizedString("select_group", comment: ""))
                .font(.appHeadlineMd())
                .foregroundColor(.appOnSurface)

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(viewModel.firebase.userGroups) { group in
                        Button(action: {
                            viewModel.selectGroup(id: group.groupId)
                            isPresented = false
                        }) {
                            HStack {
                                Text(group.name)
                                    .font(.appBodyLg())
                                Spacer()
                                if viewModel.selectedGroupId == group.groupId {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.appActiveGreen)
                                }
                            }
                            .padding()
                            .background(Color.appSurfaceContainerHigh)
                            .cornerRadius(AppTheme.cornerRadiusMd)
                        }
                        .foregroundColor(.appOnSurface)
                    }

                    if viewModel.firebase.userGroups.isEmpty {
                        Text("No groups found")
                            .font(.appBodySm())
                            .foregroundColor(.appOnSurfaceVariant)
                            .padding()
                    }
                }
            }
            .frame(maxHeight: 300)

            Button(NSLocalizedString("cancel", comment: "")) {
                isPresented = false
            }
            .buttonStyle(AppButtonStyle(variant: .outline))
        }
        .padding(AppTheme.containerPadding)
        .background(Color.appSurfaceContainer)
        .cornerRadius(AppTheme.cornerRadiusLg)
        .padding(40)
    }
}
