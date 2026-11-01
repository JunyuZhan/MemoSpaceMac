import Foundation
import Testing
@testable import MemoSpaceKit

@Suite struct ConnectionProfileTests {
    @Test func defaults() {
        let profile = ConnectionProfile(host: "192.168.1.10")
        #expect(profile.displayName == "华为家庭存储")
        #expect(profile.port == 445)
        #expect(profile.knownShares == ["家庭共享"])
        #expect(profile.effectiveUsername == "guest")
        #expect(profile.isGuest)
    }

    @Test func effectiveUsernameWhenNotGuest() {
        var profile = ConnectionProfile(host: "nas", username: "alice")
        profile.isGuest = false
        #expect(profile.effectiveUsername == "alice")
    }

    @Test func codableRoundTrip() throws {
        let profile = ConnectionProfile(host: "nas.local", port: 1445, username: "bob",
                                        isGuest: false, knownShares: ["家庭共享", "个人共享"],
                                        lastShare: "个人共享")
        let data = try JSONEncoder().encode(profile)
        let decoded = try JSONDecoder().decode(ConnectionProfile.self, from: data)
        #expect(decoded == profile)
    }

    @Test func userDefaultsProfileStoreRoundTrip() throws {
        let suite = "MemoSpaceKitTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = UserDefaultsProfileStore(defaults: defaults)
        #expect(store.load() == [])

        let profiles = [ConnectionProfile(host: "10.0.0.2"), ConnectionProfile(host: "10.0.0.3")]
        store.save(profiles)
        #expect(store.load() == profiles)
    }
}
