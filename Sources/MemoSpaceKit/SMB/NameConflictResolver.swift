import Foundation

public enum NameConflictResolver {
    public static func uniqueName(for name: String, existing: Set<String>) -> String {
        guard existing.contains(name) else { return name }
        let ext = (name as NSString).pathExtension
        let base = ext.isEmpty ? name : String(name.dropLast(ext.count + 1))
        var counter = 1
        while true {
            let candidate = ext.isEmpty ? "\(base) (\(counter))" : "\(base) (\(counter)).\(ext)"
            if !existing.contains(candidate) { return candidate }
            counter += 1
        }
    }
}
