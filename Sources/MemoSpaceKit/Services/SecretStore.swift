import Foundation

public protocol SecretStore: Sendable {
    func password(for profileID: UUID) throws -> String?
    func setPassword(_ password: String?, for profileID: UUID) throws
}

public final class InMemorySecretStore: SecretStore, @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [UUID: String] = [:]

    public init() {}

    public func password(for profileID: UUID) throws -> String? {
        lock.lock()
        defer { lock.unlock() }
        return storage[profileID]
    }

    public func setPassword(_ password: String?, for profileID: UUID) throws {
        lock.lock()
        defer { lock.unlock() }
        storage[profileID] = password
    }
}
