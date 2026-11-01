import Foundation

public enum FileKind: String, Sendable, CaseIterable {
    case folder, image, video, audio, pdf, text, archive, other
}

public enum FileTypeClassifier {
    private static let imageExtensions: Set<String> = [
        "jpg", "jpeg", "png", "heic", "heif", "webp", "gif", "bmp", "tif", "tiff", "raw", "dng"
    ]
    private static let videoExtensions: Set<String> = [
        "mp4", "mov", "m4v", "mkv", "avi", "wmv", "flv", "webm", "ts", "m2ts", "3gp"
    ]
    private static let audioExtensions: Set<String> = [
        "mp3", "m4a", "aac", "wav", "flac", "aiff", "ape", "ogg", "wma", "opus"
    ]
    private static let textExtensions: Set<String> = [
        "txt", "md", "markdown", "rtf", "csv", "json", "xml", "yml", "yaml",
        "log", "swift", "js", "ts", "html", "css", "sh", "py"
    ]
    private static let archiveExtensions: Set<String> = [
        "zip", "rar", "7z", "tar", "gz", "tgz", "bz2", "xz", "iso", "dmg"
    ]

    public static func kind(for name: String, isDirectory: Bool) -> FileKind {
        if isDirectory { return .folder }
        let ext = (name as NSString).pathExtension.lowercased()
        guard !ext.isEmpty else { return .other }
        if imageExtensions.contains(ext) { return .image }
        if videoExtensions.contains(ext) { return .video }
        if audioExtensions.contains(ext) { return .audio }
        if ext == "pdf" { return .pdf }
        if textExtensions.contains(ext) { return .text }
        if archiveExtensions.contains(ext) { return .archive }
        return .other
    }

    public static func kind(for url: URL) -> FileKind {
        var isDirectory: ObjCBool = false
        FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory)
        return kind(for: url.lastPathComponent, isDirectory: isDirectory.boolValue)
    }
}
