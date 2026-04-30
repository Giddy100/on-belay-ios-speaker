import SwiftUI

struct JoinGroupDialog: View {
    @Binding var isPresented: Bool
    @State private var searchQuery = ""
    @State private var searchResults: [Group] = []
    @State private var selectedGroup: Group?
    @State private var showingCodeEntry = false
    @State private var joinCode = ""

    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    TextField(NSLocalizedString("name", comment: ""), text: $searchQuery)
                        .textFieldStyle(.roundedBorder)
                    Button(action: search) {
                        Image(systemName: "magnifyingglass")
                    }
                }
                .padding()

                List(searchResults, selection: $selectedGroup) { group in
                    VStack(alignment: .leading) {
                        Text(group.name)
                            .font(.headline)
                        Text(group.createdByName)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .tag(group)
                }

                Spacer()

                HStack {
                    Button(NSLocalizedString("cancel", comment: "")) { isPresented = false }
                    Spacer()
                    Button(NSLocalizedString("join", comment: "")) {
                        showingCodeEntry = true
                    }
                    .disabled(selectedGroup == nil)
                }
                .padding()
            }
            .navigationTitle(NSLocalizedString("join_group", comment: ""))
            .sheet(isPresented: $showingCodeEntry) {
                CodeEntryDialog(isPresented: $showingCodeEntry, onJoin: join)
            }
        }
    }

    func search() {
        Task {
            searchResults = await FirebaseService.shared.searchGroups(query: searchQuery)
        }
    }

    func join(code: String) {
        guard let group = selectedGroup else { return }
        Task {
            if await FirebaseService.shared.joinGroup(groupId: group.groupId, code: code) {
                isPresented = false
            }
        }
    }
}

struct CodeEntryDialog: View {
    @Binding var isPresented: Bool
    var onJoin: (String) -> Void
    @State private var code = ""

    var body: some View {
        VStack(spacing: 20) {
            Text(NSLocalizedString("enter_code", comment: ""))
                .font(.headline)
            TextField("0000", text: $code)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .font(.largeTitle)
                .onChange(of: code) { _, newValue in
                    if newValue.count > 4 {
                        code = String(newValue.prefix(4))
                    }
                }

            HStack {
                Button(NSLocalizedString("cancel", comment: "")) { isPresented = false }
                Spacer()
                Button(NSLocalizedString("join", comment: "")) {
                    onJoin(code)
                }
                .disabled(code.count != 4)
            }
        }
        .padding()
        .presentationDetents([.height(200)])
    }
}
