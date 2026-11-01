import Foundation

public protocol ProfileStore: Sendable {
    func load() -> [ConnectionProfile]
    func save(_ profiles: [ConnectionProfile])
}

public struct UserDefaultsProfileStore: ProfileStore, @unchecked Sendable {
    private let defaults: UserDefaults
    private let key: String

    public init(defaults: UserDefaults = .standard, key: String = "profiles.v1") {
        self.defaults = defaults
        self.key = key
    }

    public func load() -> [ConnectionProfile] {
        guard let data = defaults.data(forKey: key) else { return [] }
        return (try? JSONDecoder().decode([ConnectionProfile].self, from: data)) ?? []
    }

    public func save(_ profiles: [ConnectionProfile]) {
        guard let data = try? JSONEncoder().encode(profiles) else { return }
        defaults.set(data, forKey: key)
    }
}
