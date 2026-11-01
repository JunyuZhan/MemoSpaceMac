import Foundation
import Combine
import SwiftUI
import MemoSpaceKit

@MainActor
final class AppModel: ObservableObject {
    enum ConnectionState: Equatable {
        case disconnected
        case connecting
        case connected
        case failed(String)
    }

    enum ViewMode: String, CaseIterable, Identifiable {
        case grid, list
        var id: String { rawValue }
        var title: String { self == .grid ? "网格" : "列表" }
        var symbol: String { self == .grid ? "square.grid.2x2" : "list.bullet" }
    }

    enum ConflictPolicy: String, CaseIterable, Identifiable {
        case ask, overwrite, skip, keepBoth, cancel
        var id: String { rawValue }
        var title: String {
            switch self {
            case .ask: return "每次询问"
            case .overwrite: return "覆盖"
            case .skip: return "跳过"
            case .keepBoth: return "保留两者"
            case .cancel: return "取消本批"
            }
        }
    }

    struct ConflictRequest: Identifiable {
        let id = UUID()
        let path: String
        let continuation: CheckedContinuation<ConflictPolicy, Never>
    }

    @Published private(set) var connectionState: ConnectionState = .disconnected
    @Published private(set) var devices: [DiscoveredDevice] = []
    @Published private(set) var profile: ConnectionProfile?
    @Published private(set) var shares: [String] = []
    @Published private(set) var currentPath: String = "/"
    @Published private(set) var items: [RemoteItem] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isDiscovering = false
    @Published var selection: Set<RemoteItem.ID> = []
    @Published var sortKey: SortKey = .name
    @Published var sortOrder: ItemSortOrder = .ascending
    @Published var searchText: String = ""
    @Published var viewMode: ViewMode = .grid
    @Published var showHiddenFiles = UserDefaults.standard.bool(forKey: "showHiddenFiles") {
        didSet { UserDefaults.standard.set(showHiddenFiles, forKey: "showHiddenFiles") }
    }
    @Published var errorMessage: String?
    @Published var pendingConflict: ConflictRequest?
    @Published var conflictPolicy: ConflictPolicy = .ask
    @Published var previewItem: RemoteItem?
    @Published var isShowingTransferCenter = false
    @Published var isShowingSettings = false
    @Published var isShowingConnect = true
    @Published var searchFocusRequest = 0
    @Published var deleteConfirmationRequested = false

    let connection: SMBConnection
    let transferQueue = TransferQueue(limit: 2)
    let thumbnailService: ThumbnailService
    let downloadCache: DiskCache
    let thumbnailCache: DiskCache
    let profileStore: any ProfileStore
    let secretStore: any SecretStore
    let discovery: any DeviceDiscovering
    let downloadDirectory: URL

    private var history: [String] = ["/"]
    private var historyIndex = 0
    private var cancelCurrentBatch = false
    private var queueObservation: AnyCancellable?

    init(connection: SMBConnection = SMBConnection(),
         profileStore: any ProfileStore = UserDefaultsProfileStore(),
         secretStore: any SecretStore = KeychainStore(),
         discovery: any DeviceDiscovering = CompositeDiscovery(),
         downloadCache: DiskCache,
         thumbnailCache: DiskCache,
         downloadDirectory: URL = FileManager.default.urls(for: .downloadsDirectory,
                                                            in: .userDomainMask)[0]) {
        self.connection = connection
        self.profileStore = profileStore
        self.secretStore = secretStore
        self.discovery = discovery
        self.downloadCache = downloadCache
        self.thumbnailCache = thumbnailCache
        self.thumbnailService = ThumbnailService(cache: thumbnailCache)
        self.downloadDirectory = downloadDirectory
        self.queueObservation = transferQueue.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }
    }

    static func makeDefault() -> AppModel {
        let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("MemoSpaceMac", isDirectory: true)
        func makeCache(_ name: String) -> DiskCache {
            let directory = base.appendingPathComponent(name, isDirectory: true)
            if let cache = try? DiskCache(configuration: .init(directory: directory, maxBytes: 1 << 30)) {
                return cache
            }
            let fallback = FileManager.default.temporaryDirectory
                .appendingPathComponent("MemoSpaceMac-\(name)", isDirectory: true)
            return try! DiskCache(configuration: .init(directory: fallback, maxBytes: 1 << 30))
        }
        return AppModel(downloadCache: makeCache("Downloads"), thumbnailCache: makeCache("Thumbnails"))
    }

    var visibleItems: [RemoteItem] {
        var filtered = showHiddenFiles
            ? items
            : items.filter { !FileVisibility.isSystemHidden($0.name) }
        if !searchText.isEmpty {
            filtered = filtered.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        return ItemSorter.sorted(filtered, by: sortKey, order: sortOrder)
    }

    var selectedItems: [RemoteItem] {
        items.filter { selection.contains($0.id) }
    }

    var canGoBack: Bool { historyIndex > 0 }
    var canGoForward: Bool { historyIndex < history.count - 1 }
    var canGoUp: Bool { currentPath != "/" }

    var breadcrumbs: [(name: String, path: String)] {
        var result: [(String, String)] = [("根目录", "/")]
        var path = ""
        for component in RemotePath.components(currentPath) {
            path += "/" + component
            result.append((component, path))
        }
        return result
    }

    func startDiscovery() async {
        isDiscovering = true
        devices = await discovery.discover(timeout: 3)
        isDiscovering = false
    }

    func loadSavedProfiles() -> [ConnectionProfile] {
        profileStore.load()
    }

    func password(for profile: ConnectionProfile) -> String? {
        try? secretStore.password(for: profile.id)
    }

    func connect(profile: ConnectionProfile, password: String, share: String,
                 rememberPassword: Bool) async {
        connectionState = .connecting
        errorMessage = nil
        do {
            try await connection.connect(profile: profile, password: password, share: share)
            if rememberPassword {
                try? secretStore.setPassword(password, for: profile.id)
            } else {
                try? secretStore.setPassword(nil, for: profile.id)
            }
            var saved = profile
            saved.lastShare = share
            var profiles = profileStore.load().filter { $0.id != profile.id }
            profiles.insert(saved, at: 0)
            profileStore.save(profiles)

            self.profile = saved
            self.shares = profile.knownShares
            self.connectionState = .connected
            self.isShowingConnect = false
            self.history = ["/"]
            self.historyIndex = 0
            await navigate(to: "/")
            await refreshShares()
        } catch {
            let mapped = SMBError.map(error)
            connectionState = .failed(mapped.localizedDescription)
            errorMessage = mapped.localizedDescription
        }
    }

    func disconnect() async {
        await connection.disconnect()
        connectionState = .disconnected
        profile = nil
        items = []
        selection = []
        isShowingConnect = true
    }

    func refreshShares() async {
        guard let profile else { return }
        let password = (try? secretStore.password(for: profile.id)) ?? ""
        if let names = try? await connection.listShares(profile: profile, password: password),
           !names.isEmpty {
            shares = names
            var updated = profile
            updated.knownShares = names
            self.profile = updated
            profileStore.save([updated] + profileStore.load().filter { $0.id != profile.id })
        }
    }

    func selectShare(_ share: String) async {
        guard let profile else { return }
        let password = (try? secretStore.password(for: profile.id)) ?? ""
        do {
            try await connection.connect(profile: profile, password: password, share: share)
            var updated = profile
            updated.lastShare = share
            self.profile = updated
            history = ["/"]
            historyIndex = 0
            await navigate(to: "/")
        } catch {
            errorMessage = SMBError.map(error).localizedDescription
        }
    }

    func navigate(to path: String) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let normalized = try RemotePath.normalize(path)
            items = try await connection.listDirectory(path: normalized)
            currentPath = normalized
            selection = []
            searchText = ""
        } catch {
            errorMessage = SMBError.map(error, path: path).localizedDescription
        }
    }

    func open(_ item: RemoteItem) async {
        guard item.isDirectory else {
            previewItem = item
            return
        }
        pushHistory(item.path)
        await navigate(to: item.path)
    }

    func goBack() async {
        guard canGoBack else { return }
        historyIndex -= 1
        await navigate(to: history[historyIndex])
    }

    func goForward() async {
        guard canGoForward else { return }
        historyIndex += 1
        await navigate(to: history[historyIndex])
    }

    func goUp() async {
        guard let parent = RemotePath.parent(of: currentPath) else { return }
        pushHistory(parent)
        await navigate(to: parent)
    }

    func refresh() async {
        await navigate(to: currentPath)
    }

    func createFolder(named name: String) async {
        do {
            let path = try RemotePath.appending(name, to: currentPath)
            try await connection.createDirectory(path: path)
            await refresh()
        } catch {
            errorMessage = SMBError.map(error).localizedDescription
        }
    }

    func rename(_ item: RemoteItem, to newName: String) async {
        do {
            guard let parent = RemotePath.parent(of: item.path) else { return }
            let destination = try RemotePath.appending(newName, to: parent)
            try await connection.move(from: item.path, to: destination)
            await refresh()
        } catch {
            errorMessage = SMBError.map(error).localizedDescription
        }
    }

    func delete(_ items: [RemoteItem]) async {
        for item in items {
            do {
                try await connection.remove(path: item.path)
            } catch {
                errorMessage = SMBError.map(error, path: item.path).localizedDescription
                break
            }
        }
        await refresh()
    }

    func upload(urls: [URL]) async {
        for url in urls {
            do {
                let plan = try UploadPlanner.plan(for: url)
                for entry in plan {
                    if cancelCurrentBatch {
                        cancelCurrentBatch = false
                        break
                    }
                    let remote = try RemotePath.appending(relative: entry.relativePath, to: currentPath)
                    if entry.isDirectory {
                        try? await connection.createDirectory(path: remote)
                        continue
                    }
                    guard let target = await resolveRemoteConflict(remote) else { continue }
                    let attributes = try? FileManager.default.attributesOfItem(atPath: entry.localURL.path)
                    let size = (attributes?[.size] as? NSNumber)?.int64Value ?? 0
                    let task = TransferTask(direction: .upload, displayName: entry.relativePath,
                                            remotePath: target, localURL: entry.localURL,
                                            totalBytes: size)
                    transferQueue.enqueue(task) { [connection] task, flag in
                        try await connection.upload(localURL: entry.localURL, to: target) { sent, _ in
                            Task { @MainActor in task.update(transferredBytes: sent) }
                            return !flag.isCancelled
                        }
                    }
                }
            } catch {
                errorMessage = SMBError.map(error).localizedDescription
            }
        }
        await refresh()
    }

    func download(_ items: [RemoteItem]) async {
        for item in items where !item.isDirectory {
            let local = uniqueLocalURL(for: downloadDirectory.appendingPathComponent(item.name))
            let task = TransferTask(direction: .download, displayName: item.name,
                                    remotePath: item.path, localURL: local,
                                    totalBytes: item.size)
            transferQueue.enqueue(task) { [connection] task, flag in
                try await connection.download(path: item.path, to: local) { done, _ in
                    Task { @MainActor in task.update(transferredBytes: done) }
                    return !flag.isCancelled
                }
            }
        }
    }

    func resolveConflict(_ policy: ConflictPolicy, applyToAll: Bool) {
        if applyToAll && policy != .cancel { conflictPolicy = policy }
        if policy == .cancel { cancelCurrentBatch = true }
        pendingConflict?.continuation.resume(returning: policy)
        pendingConflict = nil
    }

    func thumbnailURL(for item: RemoteItem) async -> URL? {
        try? await thumbnailService.thumbnail(for: item) { [connection] temporary in
            try await connection.download(path: item.path, to: temporary) { _, _ in true }
        }
    }

    func previewURL(for item: RemoteItem) async -> URL? {
        let key = CacheKey.make(path: item.path, size: item.size, modified: item.modified)
        if let cached = await downloadCache.url(for: key) { return cached }

        let capacity = await downloadCache.capacity()
        let useCache = item.size > 0 && item.size < capacity
        let destination = useCache
            ? FileManager.default.temporaryDirectory.appendingPathComponent("preview-\(UUID().uuidString)")
            : FileManager.default.temporaryDirectory
                .appendingPathComponent("preview-\(UUID().uuidString)-\(item.name)")
        do {
            try await connection.download(path: item.path, to: destination) { _, _ in true }
            if useCache {
                return try await downloadCache.store(fileAt: destination, key: key)
            }
            return destination
        } catch {
            errorMessage = SMBError.map(error, path: item.path).localizedDescription
            return nil
        }
    }

    private func pushHistory(_ path: String) {
        if historyIndex < history.count - 1 {
            history.removeSubrange((historyIndex + 1)...)
        }
        if history.last != path { history.append(path) }
        historyIndex = history.count - 1
    }

    private func resolveRemoteConflict(_ remote: String) async -> String? {
        guard let parent = RemotePath.parent(of: remote) else { return remote }
        let name = RemotePath.fileName(of: remote)
        let existing = Set((try? await connection.listDirectory(path: parent))?.map(\.name) ?? [])
        guard existing.contains(name) else { return remote }

        let policy = conflictPolicy == .ask ? await requestConflictDecision(path: remote) : conflictPolicy
        switch policy {
        case .skip, .cancel:
            return nil
        case .overwrite:
            return remote
        case .keepBoth, .ask:
            let unique = NameConflictResolver.uniqueName(for: name, existing: existing)
            return try? RemotePath.appending(unique, to: parent)
        }
    }

    private func requestConflictDecision(path: String) async -> ConflictPolicy {
        await withCheckedContinuation { continuation in
            pendingConflict = ConflictRequest(path: path, continuation: continuation)
        }
    }

    private func uniqueLocalURL(for url: URL) -> URL {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: url.path) else { return url }
        let existing = Set((try? fileManager.contentsOfDirectory(atPath: url.deletingLastPathComponent().path)) ?? [])
        let unique = NameConflictResolver.uniqueName(for: url.lastPathComponent, existing: existing)
        return url.deletingLastPathComponent().appendingPathComponent(unique)
    }
}
