import Foundation

public struct ShareBrowser: Sendable {
    private let factory: any SMBTransportFactory

    public init(factory: any SMBTransportFactory) {
        self.factory = factory
    }

    public func listShares(profile: ConnectionProfile, password: String) async throws -> [String] {
        do {
            let transport = try factory.makeTransport(
                host: profile.host, port: profile.port,
                username: profile.effectiveUsername, password: password
            )
            let names = try await transport.listShares()
            let visible = names.filter { !$0.hasSuffix("$") }
            if !visible.isEmpty { return visible }
            if !profile.knownShares.isEmpty { return profile.knownShares }
            throw SMBError.shareNotFound(profile.knownShares.first ?? "")
        } catch let error as SMBError {
            if !profile.knownShares.isEmpty { return profile.knownShares }
            throw error
        } catch {
            if !profile.knownShares.isEmpty { return profile.knownShares }
            throw SMBError.map(error)
        }
    }
}
