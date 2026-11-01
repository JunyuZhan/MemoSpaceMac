import Foundation

public struct UploadPlanItem: Sendable, Equatable {
    public let localURL: URL
    public let relativePath: String
    public let isDirectory: Bool

    public init(localURL: URL, relativePath: String, isDirectory: Bool) {
        self.localURL = localURL
        self.relativePath = relativePath
        self.isDirectory = isDirectory
    }
}

public enum UploadPlanner {
    public static func plan(for root: URL) throws -> [UploadPlanItem] {
        let fileManager = FileManager.default
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: root.path, isDirectory: &isDirectory) else {
            throw SMBError.notFound(root.path)
        }
        let rootName = root.lastPathComponent
        guard isDirectory.boolValue else {
            return [UploadPlanItem(localURL: root, relativePath: rootName, isDirectory: false)]
        }

        var items = [UploadPlanItem(localURL: root, relativePath: rootName, isDirectory: true)]
        guard let enumerator = fileManager.enumerator(
            at: root,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [],
            errorHandler: nil
        ) else { return items }

        let rootComponents = root.resolvingSymlinksInPath().pathComponents
        for case let url as URL in enumerator {
            let childIsDirectory = (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
            let relative = url.resolvingSymlinksInPath().pathComponents
                .dropFirst(rootComponents.count)
                .joined(separator: "/")
            items.append(UploadPlanItem(
                localURL: url,
                relativePath: rootName + "/" + relative,
                isDirectory: childIsDirectory
            ))
        }
        return items.sorted { lhs, rhs in
            let lhsDepth = lhs.relativePath.split(separator: "/").count
            let rhsDepth = rhs.relativePath.split(separator: "/").count
            if lhsDepth != rhsDepth { return lhsDepth < rhsDepth }
            if lhs.isDirectory != rhs.isDirectory { return lhs.isDirectory }
            return lhs.relativePath < rhs.relativePath
        }
    }
}
