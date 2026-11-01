import SwiftUI
import AppKit
import MemoSpaceKit

struct ItemGridView: View {
    let items: [RemoteItem]
    @EnvironmentObject private var model: AppModel
    @State private var renameTarget: RemoteItem?

    private let columns = [GridItem(.adaptive(minimum: 140, maximum: 180), spacing: 16)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 18) {
                ForEach(items) { item in
                    cell(item)
                }
            }
            .padding(16)
        }
    }

    private func cell(_ item: RemoteItem) -> some View {
        VStack(spacing: 6) {
            ThumbnailView(item: item)
                .frame(height: 110)
            Text(item.name)
                .font(.callout)
                .lineLimit(2)
                .multilineTextAlignment(.center)
            if !item.isDirectory {
                Text(ByteCountFormatter.string(fromByteCount: item.size, countStyle: .file))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(8)
        .background(model.selection.contains(item.id)
                    ? Color.accentColor.opacity(0.15) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .contentShape(Rectangle())
        .onTapGesture {
            if NSEvent.modifierFlags.contains(.command) {
                if model.selection.contains(item.id) {
                    model.selection.remove(item.id)
                } else {
                    model.selection.insert(item.id)
                }
            } else {
                model.selection = [item.id]
            }
        }
        .onTapGesture(count: 2) {
            Task { await model.open(item) }
        }
        .contextMenu {
            Button("打开") { Task { await model.open(item) } }
            Button("下载") { Task { await model.download([item]) } }
            Button("重命名") { renameTarget = item }
            Divider()
            Button("删除", role: .destructive) {
                model.selection = [item.id]
                model.deleteConfirmationRequested = true
            }
            Button("拷贝路径") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(item.path, forType: .string)
            }
        }
        .sheet(item: $renameTarget) { target in
            RenameSheet(name: target.name) { newName in
                Task { await model.rename(target, to: newName) }
            }
        }
    }
}
