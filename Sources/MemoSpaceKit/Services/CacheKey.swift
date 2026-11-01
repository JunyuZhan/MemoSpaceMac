import CryptoKit
import Foundation

public enum CacheKey {
    public static func make(path: String, size: Int64, modified: Date?) -> String {
        let stamp = modified.map { String($0.timeIntervalSince1970) } ?? "none"
        let input = "\(path)|\(size)|\(stamp)"
        let digest = SHA256.hash(data: Data(input.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
