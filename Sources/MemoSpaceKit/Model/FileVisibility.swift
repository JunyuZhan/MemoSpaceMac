import Foundation

public enum FileVisibility {
    private static let systemFileNames: Set<String> = ["thumbs.db", "desktop.ini"]

    public static func isSystemHidden(_ name: String) -> Bool {
        name.hasPrefix(".") || systemFileNames.contains(name.lowercased())
    }
}
