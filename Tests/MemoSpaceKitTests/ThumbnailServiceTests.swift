import Foundation
import Testing
@testable import MemoSpaceKit

private actor FetchCounter {
    private(set) var count = 0
    func increment() { count += 1 }
}

private struct FakeGenerator: ThumbnailGenerating {
    let data: Data
    func generateThumbnail(for url: URL, maxPixelSize: CGFloat) async throws -> Data { data }
}

@Suite struct ThumbnailServiceTests {
    private func makeService() throws -> (ThumbnailService, URL) {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let cache = try DiskCache(configuration: .init(directory: directory, maxBytes: 1_000_000))
        let service = ThumbnailService(cache: cache, generator: FakeGenerator(data: Data("png".utf8)))
        return (service, directory)
    }

    private func item(name: String, kind: FileKind, size: Int64) -> RemoteItem {
        RemoteItem(name: name, path: "/" + name, isDirectory: false, size: size,
                   modified: Date(timeIntervalSince1970: 1), kind: kind)
    }

    @Test func generatesAndCachesImageThumbnail() async throws {
        let (service, directory) = try makeService()
        defer { try? FileManager.default.removeItem(at: directory) }

        let item = item(name: "a.jpg", kind: .image, size: 100)
        let counter = FetchCounter()
        let fetch: @Sendable (URL) async throws -> Void = { url in
            await counter.increment()
            try Data("source".utf8).write(to: url)
        }
        let first = try await service.thumbnail(for: item, fetch: fetch)
        let second = try await service.thumbnail(for: item, fetch: fetch)
        #expect(first == second)
        #expect(try String(contentsOf: #require(first), encoding: .utf8) == "png")
        #expect(await counter.count == 1)
    }

    @Test func skipsOversizedSources() async throws {
        let (service, directory) = try makeService()
        defer { try? FileManager.default.removeItem(at: directory) }

        let item = item(name: "big.jpg", kind: .image, size: 60 * 1024 * 1024)
        let result = try await service.thumbnail(for: item) { _ in
            Issue.record("must not fetch")
        }
        #expect(result == nil)
    }

    @Test func skipsNonThumbnailableKinds() async throws {
        let (service, directory) = try makeService()
        defer { try? FileManager.default.removeItem(at: directory) }

        let item = item(name: "a.zip", kind: .archive, size: 10)
        let result = try await service.thumbnail(for: item) { _ in
            Issue.record("must not fetch")
        }
        #expect(result == nil)
    }

    @Test func pdfIsThumbnailable() async throws {
        let (service, directory) = try makeService()
        defer { try? FileManager.default.removeItem(at: directory) }

        let item = item(name: "a.pdf", kind: .pdf, size: 10)
        let result = try await service.thumbnail(for: item) { url in
            try Data("pdf".utf8).write(to: url)
        }
        #expect(result != nil)
    }
}
