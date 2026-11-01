import Foundation

public struct ConnectionProfile: Codable, Identifiable, Hashable, Sendable {
    public var id: UUID
    public var displayName: String
    public var host: String
    public var port: Int
    public var username: String
    public var isGuest: Bool
    public var knownShares: [String]
    public var lastShare: String?

    public init(id: UUID = UUID(),
                displayName: String = "华为家庭存储",
                host: String,
                port: Int = 445,
                username: String = "guest",
                isGuest: Bool = true,
                knownShares: [String] = ["家庭共享"],
                lastShare: String? = nil) {
        self.id = id
        self.displayName = displayName
        self.host = host
        self.port = port
        self.username = username
        self.isGuest = isGuest
        self.knownShares = knownShares
        self.lastShare = lastShare
    }

    public var effectiveUsername: String { isGuest ? "guest" : username }
}
