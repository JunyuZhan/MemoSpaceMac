import SwiftUI

struct NewFolderSheet: View {
    let onCommit: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var text = "新建文件夹"

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("新建文件夹").font(.headline)
            TextField("名称", text: $text)
                .textFieldStyle(.roundedBorder)
                .onSubmit(commit)
            HStack {
                Spacer()
                Button("取消") { dismiss() }
                Button("创建") { commit() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(text.isEmpty)
            }
        }
        .padding(20)
        .frame(width: 360)
    }

    private func commit() {
        guard !text.isEmpty else { return }
        onCommit(text)
        dismiss()
    }
}
