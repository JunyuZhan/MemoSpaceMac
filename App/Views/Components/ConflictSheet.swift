import SwiftUI

struct ConflictSheet: View {
    let request: AppModel.ConflictRequest
    @EnvironmentObject private var model: AppModel
    @State private var applyToAll = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("文件已存在").font(.headline)
            Text(request.path)
                .font(.callout)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .truncationMode(.middle)
            Toggle("应用于本批全部", isOn: $applyToAll)
            HStack {
                Button("取消本批") {
                    model.resolveConflict(.cancel, applyToAll: applyToAll)
                }
                Button("跳过") {
                    model.resolveConflict(.skip, applyToAll: applyToAll)
                }
                Button("保留两者") {
                    model.resolveConflict(.keepBoth, applyToAll: applyToAll)
                }
                Spacer()
                Button("覆盖") {
                    model.resolveConflict(.overwrite, applyToAll: applyToAll)
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 440)
        .interactiveDismissDisabled()
    }
}
