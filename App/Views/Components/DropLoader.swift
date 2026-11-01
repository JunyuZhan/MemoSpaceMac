import Foundation
import UniformTypeIdentifiers

enum DropLoader {
    static func loadURLs(from providers: [NSItemProvider]) async -> [URL] {
        await withTaskGroup(of: URL?.self) { group in
            for provider in providers {
                group.addTask {
                    await withCheckedContinuation { (continuation: CheckedContinuation<URL?, Never>) in
                        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier,
                                          options: nil) { item, _ in
                            var url: URL?
                            if let data = item as? Data {
                                url = URL(dataRepresentation: data, relativeTo: nil)
                            } else if let itemURL = item as? URL {
                                url = itemURL
                            }
                            continuation.resume(returning: url)
                        }
                    }
                }
            }
            var urls: [URL] = []
            for await url in group {
                if let url { urls.append(url) }
            }
            return urls
        }
    }
}
