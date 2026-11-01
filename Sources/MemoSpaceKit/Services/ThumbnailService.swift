import AppKit
import Foundation
import QuickLookThumbnailing

public protocol ThumbnailGenerating: Sendable {
    func generateThumbnail(for url: URL, maxPixelSize: CGFloat) async throws -> Data
}

public struct QuickLookThumbnailGenerator: ThumbnailGenerating {
    public init() {}

    public func generateThumbnail(for url: URL, maxPixelSize: CGFloat) async throws -> Data {
        let request = QLThumbnailGenerator.Request(
            fileAt: url,
            size: CGSize(width: maxPixelSize, height: maxPixelSize),
            scale: 2,
            representationTypes: .thumbnail
        )
        let representation: QLThumbnailRepresentation = try await withCheckedThrowingContinuation { continuation in
            QLThumbnailGenerator.shared.generateBestRepresentation(for: request) { representation, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let representation {
                    continuation.resume(returning: representation)
                } else {
                    continuation.resume(throwing: SMBError.other("无法生成缩略图"))
                }
            }
        }
        guard let tiff = representation.nsImage.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff),
              let data = bitmap.representation(using: .png, properties: [:]) else {
            throw SMBError.other("无法生成缩略图")
        }
        return data
    }
}

public actor ThumbnailService {
    private let cache: DiskCache
    private let generator: any ThumbnailGenerating
    private let maxConcurrent: Int
    private let maxSourceBytes: Int64
    private var active = 0
    private var waiters: [CheckedContinuation<Void, Never>] = []

    public init(cache: DiskCache,
                generator: any ThumbnailGenerating = QuickLookThumbnailGenerator(),
                maxConcurrent: Int = 3,
                maxSourceBytes: Int64 = 50 * 1024 * 1024) {
        self.cache = cache
        self.generator = generator
        self.maxConcurrent = maxConcurrent
        self.maxSourceBytes = maxSourceBytes
    }

    public func thumbnail(for item: RemoteItem,
                          fetch: @Sendable (URL) async throws -> Void) async throws -> URL? {
        guard item.kind == .image || item.kind == .pdf else { return nil }
        guard item.size <= maxSourceBytes else { return nil }

        let key = CacheKey.make(path: item.path, size: item.size, modified: item.modified)
        if let cached = await cache.url(for: key) { return cached }

        await acquire()
        defer { release() }

        if let cached = await cache.url(for: key) { return cached }

        let temporary = FileManager.default.temporaryDirectory
            .appendingPathComponent("thumb-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: temporary) }

        try await fetch(temporary)
        let data = try await generator.generateThumbnail(for: temporary, maxPixelSize: 320)
        return try await cache.store(data, key: key)
    }

    private func acquire() async {
        if active < maxConcurrent {
            active += 1
            return
        }
        await withCheckedContinuation { continuation in
            waiters.append(continuation)
        }
        active += 1
    }

    private func release() {
        active -= 1
        if !waiters.isEmpty {
            waiters.removeFirst().resume()
        }
    }
}
