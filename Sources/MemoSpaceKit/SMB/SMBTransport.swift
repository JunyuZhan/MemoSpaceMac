import Foundation

public protocol SMBTransport: Sendable {
    func listShares() async throws -> [String]
    func connectShare(name: String, encrypted: Bool) async throws
    func disconnectShare() async throws
    func listDirectory(path: String) async throws -> [[URLResourceKey: any Sendable]]
    func createDirectory(path: String) async throws
    func removeItem(path: String) async throws
    func moveItem(from: String, to: String) async throws
    func download(path: String, to localURL: URL,
                  progress: @escaping @Sendable (Int64, Int64) -> Bool) async throws
    func upload(localURL: URL, to path: String,
                progress: @escaping @Sendable (Int64) -> Bool) async throws
}

public protocol SMBTransportFactory: Sendable {
    func makeTransport(host: String, port: Int, username: String, password: String) throws -> any SMBTransport
}
