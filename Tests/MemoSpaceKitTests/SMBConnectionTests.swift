import Foundation
import Testing
@testable import MemoSpaceKit

@Suite struct SMBConnectionTests {
    private func makeSUT() -> (SMBConnection, FakeTransport) {
        let fake = FakeTransport()
        let connection = SMBConnection(factory: FakeTransportFactory(transport: fake))
        return (connection, fake)
    }

    @Test func connectStoresShareAndListsDirectory() async throws {
        let (connection, fake) = makeSUT()
        await fake.setDirectory("/照片", items: [[
            .nameKey: "a.jpg",
            .isDirectoryKey: false,
            .fileSizeKey: NSNumber(value: 10)
        ]])
        try await connection.connect(profile: ConnectionProfile(host: "nas"),
                                     password: "", share: "家庭共享")

        let items = try await connection.listDirectory(path: "/照片")
        #expect(items.map(\.name) == ["a.jpg"])
        let share = await connection.currentShare
        #expect(share == "家庭共享")
        let connected = await fake.connectedShare
        #expect(connected == "家庭共享")
    }

    @Test func traversalIsRejectedBeforeTouchingTransport() async throws {
        let (connection, _) = makeSUT()
        try await connection.connect(profile: ConnectionProfile(host: "nas"),
                                     password: "", share: "家庭共享")

        do {
            _ = try await connection.listDirectory(path: "/a/../b")
            Issue.record("expected error")
        } catch {
            #expect(error as? SMBError == .invalidName("/a/../b"))
        }
    }

    @Test func removingRootIsRejected() async throws {
        let (connection, fake) = makeSUT()
        try await connection.connect(profile: ConnectionProfile(host: "nas"),
                                     password: "", share: "家庭共享")

        do {
            try await connection.remove(path: "/")
            Issue.record("expected error")
        } catch {
            #expect(error as? SMBError == .invalidName("/"))
        }
        let removed = await fake.removedPaths
        #expect(removed.isEmpty)
    }

    @Test func reconnectsOnceOnConnectionLost() async throws {
        let (connection, fake) = makeSUT()
        await fake.setListErrors([POSIXError(.ECONNRESET)])
        try await connection.connect(profile: ConnectionProfile(host: "nas"),
                                     password: "pw", share: "家庭共享")

        let items = try await connection.listDirectory(path: "/")
        #expect(items.isEmpty)
        let connects = await fake.connectCount
        #expect(connects == 2)
    }

    @Test func doesNotRetryPermissionDenied() async throws {
        let (connection, fake) = makeSUT()
        await fake.setListErrors([POSIXError(.EACCES)])
        try await connection.connect(profile: ConnectionProfile(host: "nas"),
                                     password: "", share: "家庭共享")

        do {
            _ = try await connection.listDirectory(path: "/secret")
            Issue.record("expected error")
        } catch {
            #expect(error as? SMBError == .permissionDenied)
        }
        let connects = await fake.connectCount
        #expect(connects == 1)
    }

    @Test func downloadCreatesLocalParentDirectory() async throws {
        let (connection, _) = makeSUT()
        try await connection.connect(profile: ConnectionProfile(host: "nas"),
                                     password: "", share: "家庭共享")
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        let target = directory.appendingPathComponent("a.txt")
        defer { try? FileManager.default.removeItem(at: directory) }

        try await connection.download(path: "/a.txt", to: target) { _, _ in true }
        #expect(try String(contentsOf: target, encoding: .utf8) == "hello")
    }

    @Test func uploadAndMoveUseNormalizedPaths() async throws {
        let (connection, fake) = makeSUT()
        try await connection.connect(profile: ConnectionProfile(host: "nas"),
                                     password: "", share: "家庭共享")
        let source = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try Data("x".utf8).write(to: source)
        defer { try? FileManager.default.removeItem(at: source) }

        try await connection.upload(localURL: source, to: "/dir//a.txt") { _, _ in true }
        try await connection.move(from: "/dir/a.txt", to: "/dir/b.txt")

        let uploaded = await fake.uploaded
        #expect(uploaded.map(\.path) == ["/dir/a.txt"])
        let moves = await fake.moves
        #expect(moves.map(\.from) == ["/dir/a.txt"])
        #expect(moves.map(\.to) == ["/dir/b.txt"])
    }

    @Test func disconnectClearsState() async throws {
        let (connection, fake) = makeSUT()
        try await connection.connect(profile: ConnectionProfile(host: "nas"),
                                     password: "", share: "家庭共享")
        await connection.disconnect()
        let share = await connection.currentShare
        #expect(share == nil)
        let disconnects = await fake.disconnectCount
        #expect(disconnects == 1)
    }
}
