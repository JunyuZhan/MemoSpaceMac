import Foundation

public actor DiskCache {
    public struct Configuration: Sendable {
        public var directory: URL
        public var maxBytes: Int64
        public var checkIntervalBytes: Int64

        public init(directory: URL, maxBytes: Int64,
                    checkIntervalBytes: Int64 = 100 * 1024 * 1024) {
            self.directory = directory
            self.maxBytes = maxBytes
            self.checkIntervalBytes = checkIntervalBytes
        }
    }

    private static let indexFileName = "index.json"

    private let configuration: Configuration
    private let fileManager = FileManager.default
    private var index: LRUIndex
    private var bytesSinceCheck: Int64 = 0

    public init(configuration: Configuration) throws {
        self.configuration = configuration
        try FileManager.default.createDirectory(
            at: configuration.directory,
            withIntermediateDirectories: true
        )
        self.index = Self.loadIndex(from: configuration.directory)
    }

    public func url(for key: String) -> URL? {
        let url = fileURL(for: key)
        guard fileManager.fileExists(atPath: url.path) else {
            if index.entries[key] != nil {
                index.remove(key: key)
                persistIndex()
            }
            return nil
        }
        index.touch(key: key)
        persistIndex()
        return url
    }

    @discardableResult
    public func store(_ data: Data, key: String) throws -> URL {
        let url = fileURL(for: key)
        try data.write(to: url, options: .atomic)
        index.insert(key: key, size: Int64(data.count))
        bytesSinceCheck += Int64(data.count)
        enforceLimitIfNeeded()
        persistIndex()
        return url
    }

    @discardableResult
    public func store(fileAt source: URL, key: String) throws -> URL {
        let url = fileURL(for: key)
        if fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
        }
        try fileManager.moveItem(at: source, to: url)
        let attributes = try? fileManager.attributesOfItem(atPath: url.path)
        let size = (attributes?[.size] as? NSNumber)?.int64Value ?? 0
        index.insert(key: key, size: size)
        bytesSinceCheck += size
        enforceLimitIfNeeded()
        persistIndex()
        return url
    }

    public func clear() throws {
        let contents = try fileManager.contentsOfDirectory(
            at: configuration.directory,
            includingPropertiesForKeys: nil
        )
        for url in contents {
            try? fileManager.removeItem(at: url)
        }
        index.removeAll()
        bytesSinceCheck = 0
    }

    public func totalBytes() -> Int64 {
        index.totalSize
    }

    public func capacity() -> Int64 {
        configuration.maxBytes
    }

    private func fileURL(for key: String) -> URL {
        configuration.directory.appendingPathComponent(key)
    }

    private func enforceLimitIfNeeded() {
        guard index.totalSize > configuration.maxBytes
                || bytesSinceCheck >= configuration.checkIntervalBytes else { return }
        for key in index.evictionCandidates(toFit: configuration.maxBytes) {
            try? fileManager.removeItem(at: fileURL(for: key))
            index.remove(key: key)
        }
        bytesSinceCheck = 0
    }

    private func persistIndex() {
        guard let data = try? JSONEncoder().encode(index) else { return }
        try? data.write(
            to: configuration.directory.appendingPathComponent(Self.indexFileName),
            options: .atomic
        )
    }

    private static func loadIndex(from directory: URL) -> LRUIndex {
        let url = directory.appendingPathComponent(indexFileName)
        guard let data = try? Data(contentsOf: url),
              let index = try? JSONDecoder().decode(LRUIndex.self, from: data) else {
            return LRUIndex()
        }
        return index
    }
}
