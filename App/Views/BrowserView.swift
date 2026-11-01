import SwiftUI
import UniformTypeIdentifiers
import MemoSpaceKit

struct BrowserView: View {
    @EnvironmentObject private var model: AppModel
    @State private var renameTarget: RemoteItem?
    @State private var showNewFolder = false
    @State private var isImporting = false
    @State private var isDropTargeted = false
    @FocusState private var searchFocused: Bool

    var body: some View {
        NavigationSplitView {
            SidebarView()
                .navigationSplitViewColumnWidth(min: 200, ideal: 220)
        } detail: {
            VStack(spacing: 0) {
                toolbar
                Divider()
                content
                Divider()
                statusBar
            }
        }
        .sheet(item: $renameTarget) { item in
            RenameSheet(name: item.name) { newName in
                Task { await model.rename(item, to: newName) }
            }
        }
        .sheet(isPresented: $showNewFolder) {
            NewFolderSheet { name in
                Task { await model.createFolder(named: name) }
            }
        }
        .sheet(item: $model.previewItem) { item in
            PreviewPanel(item: item)
                .environmentObject(model)
        }
        .sheet(isPresented: $model.isShowingTransferCenter) {
            TransferCenterView()
                .environmentObject(model)
        }
        .sheet(item: $model.pendingConflict) { request in
            ConflictSheet(request: request)
                .environmentObject(model)
        }
        .confirmationDialog("确定删除选中的项目？",
                            isPresented: $model.deleteConfirmationRequested,
                            titleVisibility: .visible) {
            Button("删除", role: .destructive) {
                Task { await model.delete(model.selectedItems) }
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("将删除 \(model.selection.count) 个项目，SMB 删除后无法恢复。")
        }
        .fileImporter(isPresented: $isImporting, allowedContentTypes: [.item],
                      allowsMultipleSelection: true) { result in
            if case let .success(urls) = result {
                Task { await model.upload(urls: urls) }
            }
        }
        .overlay {
            if isDropTargeted {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.accentColor, style: StrokeStyle(lineWidth: 2, dash: [8]))
                    .padding(8)
                    .allowsHitTesting(false)
            }
        }
        .onDrop(of: [.fileURL], isTargeted: $isDropTargeted) { providers in
            Task {
                let urls = await DropLoader.loadURLs(from: providers)
                await model.upload(urls: urls)
            }
            return true
        }
        .focusable()
        .onKeyPress(.space) {
            guard let item = model.selectedItems.first else { return .ignored }
            if item.isDirectory {
                Task { await model.open(item) }
            } else {
                model.previewItem = item
            }
            return .handled
        }
        .onKeyPress(.return) {
            guard let item = model.selectedItems.first else { return .ignored }
            renameTarget = item
            return .handled
        }
        .onDeleteCommand {
            guard !model.selection.isEmpty else { return }
            model.deleteConfirmationRequested = true
        }
    }

    private var toolbar: some View {
        HStack(spacing: 10) {
            Button {
                Task { await model.goBack() }
            } label: { Image(systemName: "chevron.left") }
                .disabled(!model.canGoBack)

            Button {
                Task { await model.goForward() }
            } label: { Image(systemName: "chevron.right") }
                .disabled(!model.canGoForward)

            Button {
                Task { await model.goUp() }
            } label: { Image(systemName: "arrow.up") }
                .disabled(!model.canGoUp)

            breadcrumbs
                .layoutPriority(1)

            Spacer(minLength: 8)

            TextField("在当前文件夹中搜索", text: $model.searchText)
                .textFieldStyle(.roundedBorder)
                .frame(width: 180)
                .focused($searchFocused)
                .onChange(of: model.searchFocusRequest) { _, _ in searchFocused = true }

            Menu {
                Picker("排序字段", selection: $model.sortKey) {
                    ForEach(SortKey.allCases, id: \.self) { key in
                        Text(key.title).tag(key)
                    }
                }
                Picker("顺序", selection: $model.sortOrder) {
                    Text("升序").tag(ItemSortOrder.ascending)
                    Text("降序").tag(ItemSortOrder.descending)
                }
            } label: { Image(systemName: "arrow.up.arrow.down") }
                .menuStyle(.borderlessButton)
                .fixedSize()

            Picker("视图", selection: $model.viewMode) {
                ForEach(AppModel.ViewMode.allCases) { mode in
                    Image(systemName: mode.symbol).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 80)

            Button {
                isImporting = true
            } label: { Image(systemName: "square.and.arrow.up") }
                .help("上传文件或文件夹")

            Button {
                showNewFolder = true
            } label: { Image(systemName: "folder.badge.plus") }
                .help("新建文件夹")

            Button {
                Task { await model.refresh() }
            } label: { Image(systemName: "arrow.clockwise") }
                .help("刷新")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var breadcrumbs: some View {
        HStack(spacing: 2) {
            ForEach(Array(model.breadcrumbs.enumerated()), id: \.offset) { index, crumb in
                if index > 0 {
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                Button(crumb.name) {
                    Task { await model.navigate(to: crumb.path) }
                }
                .buttonStyle(.plain)
                .foregroundStyle(index == model.breadcrumbs.count - 1 ? .primary : .secondary)
            }
        }
        .lineLimit(1)
        .truncationMode(.middle)
    }

    @ViewBuilder
    private var content: some View {
        if model.isLoading {
            ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if model.visibleItems.isEmpty {
            ContentUnavailableView {
                Label(model.searchText.isEmpty ? "文件夹为空" : "没有匹配项", systemImage: "folder")
            } description: {
                Text(model.searchText.isEmpty ? "拖入文件即可上传" : "搜索仅作用于当前文件夹")
            }
        } else if model.viewMode == .grid {
            ItemGridView(items: model.visibleItems)
        } else {
            ItemListView(items: model.visibleItems)
        }
    }

    private var statusBar: some View {
        HStack {
            Text("\(model.visibleItems.count) 个项目")
            if !model.selection.isEmpty {
                Text("· 已选 \(model.selection.count) 个")
            }
            Spacer()
            if model.transferQueue.activeCount > 0 {
                Text("传输中 \(model.transferQueue.activeCount)")
                    .foregroundStyle(.secondary)
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }
}

private extension SortKey {
    var title: String {
        switch self {
        case .name: return "名称"
        case .size: return "大小"
        case .modified: return "修改时间"
        case .kind: return "类型"
        }
    }
}
