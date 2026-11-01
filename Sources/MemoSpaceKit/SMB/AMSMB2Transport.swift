import Foundation
import AMSMB2

public struct AMSMB2TransportFactory: SMBTransportFactory {
    public init() {}

    public func makeTransport(host: String, port: Int,
                              username: String, password: String) throws -> any SMBTransport {
        var components = URLComponents()
        components.scheme = "smb"
        components.host = host
        components.port = port
        components.user = username
        guard let url = components.url else {
            throw SMBError.other("设备地址无效")
        }
        let credential = URLCredential(user: username, password: password, persistence: .none)
        guard let manager = SMB2Manager(url: url, credential: credential) else {
            throw SMBError.other("无法创建 SMB 连接")
        }
        return AMSMB2Transport(manager: manager)
    }
}

public final class AMSMB2Transport: SMBTransport, @unchecked Sendable {
    private let manager: SMB2Manager

    init(manager: SMB2Manager) {
        self.manager = manager
        manager.timeout = 15
    }

    public func listShares() async throws -> [String] {
        try await manager.listShares(enumerateHidden: false).map(\.name)
    }

    public func connectShare(name: String, encrypted: Bool) async throws {
        try await manager.connectShare(name: name, encrypted: encrypted)
    }

    public func disconnectShare() async throws {
        try await manager.disconnectShare(gracefully: false)
    }

    public func listDirectory(path: String) async throws -> [[URLResourceKey: any Sendable]] {
        try await manager.contentsOfDirectory(atPath: path)
    }

    public func createDirectory(path: String) async throws {
        try await manager.createDirectory(atPath: path)
    }

    public func removeItem(path: String) async throws {
        try await manager.removeItem(atPath: path)
    }

    public func moveItem(from: String, to: String) async throws {
        try await manager.moveItem(atPath: from, toPath: to)
    }

    public func download(path: String, to localURL: URL,
                         progress: @escaping @Sendable (Int64, Int64) -> Bool) async throws {
        try await manager.downloadItem(atPath: path, to: localURL) { bytes, total in
            progress(bytes, total)
        }
    }

    public func upload(localURL: URL, to path: String,
                       progress: @escaping @Sendable (Int64) -> Bool) async throws {
        try await manager.uploadItem(at: localURL, toPath: path) { bytes in
            progress(bytes)
        }
    }
}
