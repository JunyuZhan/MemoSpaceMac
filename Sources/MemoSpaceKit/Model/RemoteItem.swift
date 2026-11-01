import Foundation

public struct RemoteItem: Identifiable, Hashable, Sendable {
    public var id: String { path }
    public let name: String
    public let path: String
    public let isDirectory: Bool
    public let size: Int64
    public let modified: Date?
    public let kind: FileKind

    public init(name: String, path: String, isDirectory: Bool,
                size: Int64, modified: Date?, kind: FileKind) {
        self.name = name
        self.path = path
        self.isDirectory = isDirectory
        self.size = size
        self.modified = modified
        self.kind = kind
    }

    public init?(attributes: [URLResourceKey: any Sendable], parentPath: String) {
        guard let name = attributes[.nameKey] as? String,
              RemotePath.isValidName(name),
              let path = try? RemotePath.appending(name, to: parentPath)
        else { return nil }
        let isDirectory = attributes[.isDirectoryKey] as? Bool ?? false
        let size = (attributes[.fileSizeKey] as? NSNumber)?.int64Value ?? 0
        let modified = attributes[.contentModificationDateKey] as? Date
        self.init(name: name, path: path, isDirectory: isDirectory, size: size,
                  modified: modified,
                  kind: FileTypeClassifier.kind(for: name, isDirectory: isDirectory))
    }
}
