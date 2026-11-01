import Foundation
@testable import MemoSpaceKit

actor FakeTransport: SMBTransport {
    var connectCount = 0
    var disconnectCount = 0
    var connectedShare: String?
    var shares: [String] = []
    var directories: [String: [[URLResourceKey: any Sendable]]] = [:]
    var listErrorQueue: [Error] = []
    var removedPaths: [String] = []
    var createdDirectories: [String] = []
    var moves: [(from: String, to: String)] = []
    var uploaded: [(url: URL, path: String)] = []

    func setDirectory(_ path: String, items: [[URLResourceKey: any Sendable]]) {
        directories[path] = items
    }

    func setListErrors(_ errors: [Error]) {
        listErrorQueue = errors
    }

    func setShares(_ names: [String]) {
        shares = names
    }

    func listShares() async throws -> [String] { shares }

    func connectShare(name: String, encrypted: Bool) async throws {
        connectCount += 1
        connectedShare = name
    }

    func disconnectShare() async throws {
        disconnectCount += 1
        connectedShare = nil
    }

    func listDirectory(path: String) async throws -> [[URLResourceKey: any Sendable]] {
        if !listErrorQueue.isEmpty { throw listErrorQueue.removeFirst() }
        return directories[path] ?? []
    }

    func createDirectory(path: String) async throws {
        createdDirectories.append(path)
    }

    func removeItem(path: String) async throws {
        removedPaths.append(path)
    }

    func moveItem(from: String, to: String) async throws {
        moves.append((from, to))
    }

    func download(path: String, to localURL: URL,
                  progress: @escaping @Sendable (Int64, Int64) -> Bool) async throws {
        try Data("hello".utf8).write(to: localURL)
        _ = progress(5, 5)
    }

    func upload(localURL: URL, to path: String,
                progress: @escaping @Sendable (Int64) -> Bool) async throws {
        uploaded.append((localURL, path))
        _ = progress(1)
    }
}

struct FakeTransportFactory: SMBTransportFactory {
    let transport: FakeTransport
    var error: SMBError? = nil

    func makeTransport(host: String, port: Int,
                       username: String, password: String) throws -> any SMBTransport {
        if let error { throw error }
        return transport
    }
}
