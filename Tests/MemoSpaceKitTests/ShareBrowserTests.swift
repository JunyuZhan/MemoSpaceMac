import Foundation
import Testing
@testable import MemoSpaceKit

@Suite struct ShareBrowserTests {
    @Test func filtersAdministrativeShares() async throws {
        let fake = FakeTransport()
        await fake.setShares(["家庭共享", "个人共享", "IPC$", "C$"])
        let browser = ShareBrowser(factory: FakeTransportFactory(transport: fake))
        let names = try await browser.listShares(profile: ConnectionProfile(host: "nas"), password: "")
        #expect(names == ["家庭共享", "个人共享"])
    }

    @Test func fallsBackToKnownSharesOnFailure() async throws {
        let fake = FakeTransport()
        let profile = ConnectionProfile(host: "nas", knownShares: ["家庭共享", "个人共享"])
        let browser = ShareBrowser(factory: FakeTransportFactory(transport: fake, error: .permissionDenied))
        let names = try await browser.listShares(profile: profile, password: "")
        #expect(names == ["家庭共享", "个人共享"])
    }

    @Test func throwsWhenNoFallbackAvailable() async throws {
        let fake = FakeTransport()
        let profile = ConnectionProfile(host: "nas", knownShares: [])
        let browser = ShareBrowser(factory: FakeTransportFactory(transport: fake, error: .permissionDenied))
        do {
            _ = try await browser.listShares(profile: profile, password: "")
            Issue.record("expected error")
        } catch {
            #expect(error as? SMBError == .permissionDenied)
        }
    }
}
