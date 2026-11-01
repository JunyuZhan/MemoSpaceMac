import Foundation

public enum RemotePathError: Error, Equatable, LocalizedError {
    case traversal(String)
    case invalidName(String)
    case invalidCharacter

    public var errorDescription: String? {
        switch self {
        case .traversal: return "路径包含非法的上级目录引用"
        case let .invalidName(name): return "文件名「\(name)」不合法"
        case .invalidCharacter: return "路径包含不支持的字符"
        }
    }
}

public enum RemotePath {
    public static let root = "/"

    public static func normalize(_ raw: String) throws -> String {
        let unified = raw.replacingOccurrences(of: "\\", with: "/")
        if unified.contains("\0") { throw RemotePathError.invalidCharacter }
        var parts: [String] = []
        for component in unified.split(separator: "/", omittingEmptySubsequences: true) {
            let name = String(component)
            if name == "." { continue }
            if name == ".." { throw RemotePathError.traversal(raw) }
            parts.append(name)
        }
        return root + parts.joined(separator: "/")
    }

    public static func appending(_ name: String, to parent: String) throws -> String {
        guard isValidName(name) else { throw RemotePathError.invalidName(name) }
        let base = try normalize(parent)
        return base == root ? root + name : base + "/" + name
    }

    public static func appending(relative: String, to parent: String) throws -> String {
        var result = try normalize(parent)
        for component in relative.split(separator: "/", omittingEmptySubsequences: true) {
            result = try appending(String(component), to: result)
        }
        return result
    }

    public static func parent(of path: String) -> String? {
        guard let normalized = try? normalize(path), normalized != root else { return nil }
        let parts = components(normalized)
        return parts.count <= 1 ? root : root + parts.dropLast().joined(separator: "/")
    }

    public static func components(_ path: String) -> [String] {
        guard let normalized = try? normalize(path) else { return [] }
        return normalized.split(separator: "/").map(String.init)
    }

    public static func fileName(of path: String) -> String {
        components(path).last ?? ""
    }

    public static func isValidName(_ name: String) -> Bool {
        !name.isEmpty
            && name != "."
            && name != ".."
            && !name.contains("/")
            && !name.contains("\\")
            && !name.contains("\0")
    }
}
