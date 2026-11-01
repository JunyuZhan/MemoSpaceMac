import SwiftUI
import MemoSpaceKit

struct SettingsView: View {
    @EnvironmentObject private var model: AppModel
    @State private var downloadBytes: Int64 = 0
    @State private var thumbnailBytes: Int64 = 0

    var body: some View {
        Form {
            Section("传输") {
                Picker("同名冲突", selection: $model.conflictPolicy) {
                    ForEach(AppModel.ConflictPolicy.allCases) { policy in
                        Text(policy.title).tag(policy)
                    }
                }
                LabeledContent("下载目录", value: model.downloadDirectory.path)
            }

            Section("缓存") {
                LabeledContent("预览缓存",
                               value: ByteCountFormatter.string(fromByteCount: downloadBytes,
                                                                countStyle: .file))
                LabeledContent("缩略图缓存",
                               value: ByteCountFormatter.string(fromByteCount: thumbnailBytes,
                                                                countStyle: .file))
                HStack {
                    Button("清空预览缓存") {
                        Task {
                            try? await model.downloadCache.clear()
                            await refresh()
                        }
                    }
                    Button("清空缩略图缓存") {
                        Task {
                            try? await model.thumbnailCache.clear()
                            await refresh()
                        }
                    }
                }
            }

            Section("关于") {
                LabeledContent("版本", value: "0.1.0")
                Text("第一版仅支持局域网 SMB 共享；远程访问与相册功能后续提供。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .task { await refresh() }
    }

    private func refresh() async {
        downloadBytes = await model.downloadCache.totalBytes()
        thumbnailBytes = await model.thumbnailCache.totalBytes()
    }
}
