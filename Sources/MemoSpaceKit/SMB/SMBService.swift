import Foundation

public protocol SMBService: Sendable {
    func connect(profile: ConnectionProfile, password: String, share: String) async throws
    func disconnect() async
    func listShares(profile: ConnectionProfile, password: String) async throws -> [String]
    func listDirectory(path: String) async throws -> [RemoteItem]
    func createDirectory(path: String) async throws
    func remove(path: String) async throws
    func move(from: String, to: String) async throws
    func download(path: String, to localURL: URL,
                  progress: @escaping @Sendable (Int64, Int64) -> Bool) async throws
    func upload(localURL: URL, to path: String,
                progress: @escaping @Sendable (Int64, Int64) -> Bool) async throws
}
