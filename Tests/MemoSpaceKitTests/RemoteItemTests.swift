import Foundation
import Testing
@testable import MemoSpaceKit

@Suite struct RemoteItemTests {
    @Test func initFromSMBAttributes() throws {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let attributes: [URLResourceKey: any Sendable] = [
            .nameKey: "假期.jpg",
            .isDirectoryKey: false,
            .fileSizeKey: NSNumber(value: 2048),
            .contentModificationDateKey: date
        ]
        let item = try #require(RemoteItem(attributes: attributes, parentPath: "/家庭共享/照片"))
        #expect(item.name == "假期.jpg")
        #expect(item.path == "/家庭共享/照片/假期.jpg")
        #expect(item.size == 2048)
        #expect(item.modified == date)
        #expect(!item.isDirectory)
        #expect(item.kind == .image)
    }

    @Test func directoryAttributes() throws {
        let attributes: [URLResourceKey: any Sendable] = [
            .nameKey: "视频",
            .isDirectoryKey: true
        ]
        let item = try #require(RemoteItem(attributes: attributes, parentPath: "/"))
        #expect(item.path == "/视频")
        #expect(item.isDirectory)
        #expect(item.size == 0)
        #expect(item.kind == .folder)
    }

    @Test func missingNameReturnsNil() {
        #expect(RemoteItem(attributes: [:], parentPath: "/") == nil)
    }

    @Test func traversalNameIsRejected() {
        let attributes: [URLResourceKey: any Sendable] = [.nameKey: ".."]
        #expect(RemoteItem(attributes: attributes, parentPath: "/") == nil)
    }
}
