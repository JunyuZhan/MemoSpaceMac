import Foundation
import Testing
@testable import MemoSpaceKit

@Suite struct DiskCacheTests {
    private func makeCache(maxBytes: Int64) throws -> (DiskCache, URL) {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let cache = try DiskCache(configuration: .init(directory: directory, maxBytes: maxBytes,
                                                       checkIntervalBytes: 0))
        return (cache, directory)
    }

    @Test func storeAndRead() async throws {
        let (cache, directory) = try makeCache(maxBytes: 1_000)
        defer { try? FileManager.default.removeItem(at: directory) }

        let url = try await cache.store(Data("hello".utf8), key: "k1")
        #expect(try String(contentsOf: url, encoding: .utf8) == "hello")
        let hit = await cache.url(for: "k1")
        #expect(hit == url)
        let miss = await cache.url(for: "missing")
        #expect(miss == nil)
    }

    @Test func evictsOldestWhenOverLimit() async throws {
        let (cache, directory) = try makeCache(maxBytes: 10)
        defer { try? FileManager.default.removeItem(at: directory) }

        _ = try await cache.store(Data(repeating: 1, count: 6), key: "old")
        _ = try await cache.store(Data(repeating: 2, count: 6), key: "new")

        let old = await cache.url(for: "old")
        let new = await cache.url(for: "new")
        #expect(old == nil)
        #expect(new != nil)
    }

    @Test func clearRemovesAllFiles() async throws {
        let (cache, directory) = try makeCache(maxBytes: 1_000)
        defer { try? FileManager.default.removeItem(at: directory) }

        _ = try await cache.store(Data("x".utf8), key: "k1")
        try await cache.clear()
        let hit = await cache.url(for: "k1")
        #expect(hit == nil)
        let contents = try FileManager.default.contentsOfDirectory(atPath: directory.path)
        #expect(contents.isEmpty)
    }

    @Test func persistsIndexAcrossInstances() async throws {
        let (cache, directory) = try makeCache(maxBytes: 1_000)
        defer { try? FileManager.default.removeItem(at: directory) }

        _ = try await cache.store(Data("hello".utf8), key: "k1")
        let reopened = try DiskCache(configuration: .init(directory: directory, maxBytes: 1_000,
                                                          checkIntervalBytes: 0))
        let total = await reopened.totalBytes()
        let hit = await reopened.url(for: "k1")
        #expect(total == 5)
        #expect(hit != nil)
    }
}
