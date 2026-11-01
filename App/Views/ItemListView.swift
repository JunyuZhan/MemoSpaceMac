import SwiftUI
import AppKit
import MemoSpaceKit

struct ItemListView: View {
    let items: [RemoteItem]
    @EnvironmentObject private var model: AppModel
    @State private var renameTarget: RemoteItem?

    var body: some View {
        List(selection: $model.selection) {
            ForEach(items) { item in
                HStack(spacing: 8) {
                    Image(systemName: item.kind.symbolName)
                        .foregroundStyle(item.kind.tint)
                        .frame(width: 18)
                    Text(item.name).lineLimit(1)
                    Spacer()
                    if !item.isDirectory {
                        Text(ByteCountFormatter.string(fromByteCount: item.size, countStyle: .file))
                            .foregroundStyle(.secondary)
                            .frame(width: 90, alignment: .trailing)
                    }
                    Text(item.modified?.formatted(date: .abbreviated, time: .shortened) ?? "—")
                        .foregroundStyle(.secondary)
                        .frame(width: 140, alignment: .trailing)
                }
                .tag(item.id)
                .contextMenu {
                    Button("打开") { Task { await model.open(item) } }
                    Button("下载") { Task { await model.download([item]) } }
                    Button("重命名") { renameTarget = item }
                    Divider()
                    Button("删除", role: .destructive) {
                        model.selection = [item.id]
                        model.deleteConfirmationRequested = true
                    }
                }
                .onTapGesture(count: 2) {
                    Task { await model.open(item) }
                }
            }
        }
        .sheet(item: $renameTarget) { target in
            RenameSheet(name: target.name) { newName in
                Task { await model.rename(target, to: newName) }
            }
        }
    }
}
