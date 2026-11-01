import Foundation

public actor SMBConnection: SMBService {
    private let factory: any SMBTransportFactory
    private let shareBrowser: ShareBrowser
    private var transport: (any SMBTransport)?
    private var profile: ConnectionProfile?
    private var password: String?
    private var share: String?

    public init(factory: any SMBTransportFactory = AMSMB2TransportFactory()) {
        self.factory = factory
        self.shareBrowser = ShareBrowser(factory: factory)
    }

    public var currentShare: String? { share }
    public var isConnected: Bool { transport != nil }

    public func connect(profile: ConnectionProfile, password: String, share: String) async throws {
        await disconnect()
        do {
            let transport = try makeTransport(profile: profile, password: password)
            try await transport.connectShare(name: share, encrypted: false)
            self.transport = transport
            self.profile = profile
            self.password = password
            self.share = share
        } catch {
            throw SMBError.map(error)
        }
    }

    public func disconnect() async {
        if let transport {
            try? await transport.disconnectShare()
        }
        transport = nil
        profile = nil
        password = nil
        share = nil
    }

    public func listShares(profile: ConnectionProfile, password: String) async throws -> [String] {
        try await shareBrowser.listShares(profile: profile, password: password)
    }

    public func listDirectory(path: String) async throws -> [RemoteItem] {
        let normalized = try normalizedPath(path)
        let attributes = try await perform(path: normalized) {
            try await $0.listDirectory(path: normalized)
        }
        return attributes.compactMap { RemoteItem(attributes: $0, parentPath: normalized) }
    }

    public func createDirectory(path: String) async throws {
        let normalized = try nonRootPath(path)
        try await perform(path: normalized) { try await $0.createDirectory(path: normalized) }
    }

    public func remove(path: String) async throws {
        let normalized = try nonRootPath(path)
        try await perform(path: normalized) { try await $0.removeItem(path: normalized) }
    }

    public func move(from: String, to: String) async throws {
        let source = try nonRootPath(from)
        let destination = try nonRootPath(to)
        try await perform(path: source) { try await $0.moveItem(from: source, to: destination) }
    }

    public func download(path: String, to localURL: URL,
                         progress: @escaping @Sendable (Int64, Int64) -> Bool) async throws {
        let normalized = try normalizedPath(path)
        guard normalized != RemotePath.root else { throw SMBError.invalidName(path) }
        try FileManager.default.createDirectory(
            at: localURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try await perform(path: normalized) {
            try await $0.download(path: normalized, to: localURL, progress: progress)
        }
    }

    public func upload(localURL: URL, to path: String,
                       progress: @escaping @Sendable (Int64, Int64) -> Bool) async throws {
        let normalized = try nonRootPath(path)
        let attributes = try? FileManager.default.attributesOfItem(atPath: localURL.path)
        let total = (attributes?[.size] as? NSNumber)?.int64Value ?? 0
        try await perform(path: normalized) {
            try await $0.upload(localURL: localURL, to: normalized) { sent in
                progress(sent, total)
            }
        }
    }

    private func makeTransport(profile: ConnectionProfile, password: String) throws -> any SMBTransport {
        try factory.makeTransport(host: profile.host, port: profile.port,
                                  username: profile.effectiveUsername, password: password)
    }

    private func normalizedPath(_ raw: String) throws -> String {
        do {
            return try RemotePath.normalize(raw)
        } catch {
            throw SMBError.map(error, path: raw)
        }
    }

    private func nonRootPath(_ raw: String) throws -> String {
        let normalized = try normalizedPath(raw)
        guard normalized != RemotePath.root else { throw SMBError.invalidName(raw) }
        return normalized
    }

    private func perform<T>(path: String,
                            _ operation: (any SMBTransport) async throws -> T) async throws -> T {
        guard let transport else { throw SMBError.connectionLost }
        do {
            return try await operation(transport)
        } catch {
            let mapped = SMBError.map(error, path: path)
            guard mapped == .connectionLost || mapped == .timeout else { throw mapped }
            try await reconnect()
            guard let fresh = self.transport else { throw mapped }
            do {
                return try await operation(fresh)
            } catch {
                throw SMBError.map(error, path: path)
            }
        }
    }

    private func reconnect() async throws {
        guard let profile, let password, let share else { throw SMBError.connectionLost }
        if let transport {
            try? await transport.disconnectShare()
        }
        transport = nil
        do {
            let fresh = try makeTransport(profile: profile, password: password)
            try await fresh.connectShare(name: share, encrypted: false)
            transport = fresh
        } catch {
            throw SMBError.map(error)
        }
    }
}
