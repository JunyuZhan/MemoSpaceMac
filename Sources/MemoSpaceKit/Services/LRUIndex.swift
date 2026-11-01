import Foundation

public struct LRUIndex: Sendable, Codable, Equatable {
    public struct Entry: Codable, Sendable, Equatable {
        public var key: String
        public var size: Int64
        public var lastAccess: Date

        public init(key: String, size: Int64, lastAccess: Date) {
            self.key = key
            self.size = size
            self.lastAccess = lastAccess
        }
    }

    public private(set) var entries: [String: Entry] = [:]
    public private(set) var totalSize: Int64 = 0

    public init() {}

    public mutating func insert(key: String, size: Int64, at date: Date = Date()) {
        if let existing = entries[key] {
            totalSize -= existing.size
        }
        entries[key] = Entry(key: key, size: size, lastAccess: date)
        totalSize += size
    }

    public mutating func touch(key: String, at date: Date = Date()) {
        entries[key]?.lastAccess = date
    }

    public mutating func remove(key: String) {
        if let existing = entries.removeValue(forKey: key) {
            totalSize -= existing.size
        }
    }

    public mutating func removeAll() {
        entries.removeAll()
        totalSize = 0
    }

    public mutating func evictionCandidates(toFit limit: Int64) -> [String] {
        guard totalSize > limit else { return [] }
        var candidates: [String] = []
        var projected = totalSize
        for entry in entries.values.sorted(by: { $0.lastAccess < $1.lastAccess }) {
            candidates.append(entry.key)
            projected -= entry.size
            if projected <= limit { break }
        }
        return candidates
    }
}
