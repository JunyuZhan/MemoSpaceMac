import SwiftUI

struct RenameSheet: View {
    let original: String
    let onCommit: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var text: String

    init(name: String, onCommit: @escaping (String) -> Void) {
        self.original = name
        self.onCommit = onCommit
        _text = State(initialValue: name)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("重命名").font(.headline)
            TextField("名称", text: $text)
                .textFieldStyle(.roundedBorder)
                .onSubmit(commit)
            HStack {
                Spacer()
                Button("取消") { dismiss() }
                Button("确定") { commit() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(text.isEmpty || text == original)
            }
        }
        .padding(20)
        .frame(width: 360)
    }

    private func commit() {
        guard !text.isEmpty, text != original else { return }
        onCommit(text)
        dismiss()
    }
}
