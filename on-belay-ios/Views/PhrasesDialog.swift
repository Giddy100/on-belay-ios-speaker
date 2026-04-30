import SwiftUI

struct PhrasesDialog: View {
    @Binding var phrases: [Phrase]
    let isCreator: Bool
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(phrases.indices, id: \.self) { index in
                    HStack {
                        Text(phrases[index].name)
                        Spacer()
                        if phrases[index].selected {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        } else {
                            Image(systemName: "circle")
                                .foregroundColor(.gray)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if isCreator {
                            phrases[index].selected.toggle()
                        }
                    }
                }
            }
            .navigationTitle(NSLocalizedString("phrases", comment: ""))
            .toolbar {
                if isCreator {
                    ToolbarItem(placement: .confirmationAction) {
                        Button(NSLocalizedString("save", comment: "")) { dismiss() }
                    }
                    ToolbarItem(placement: .cancellationAction) {
                        Button(NSLocalizedString("cancel", comment: "")) { dismiss() }
                    }
                } else {
                    ToolbarItem(placement: .confirmationAction) {
                        Button(NSLocalizedString("cancel", comment: "")) { dismiss() }
                    }
                }
            }
        }
    }
}
