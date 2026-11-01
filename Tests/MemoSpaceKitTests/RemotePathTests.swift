import Testing
@testable import MemoSpaceKit

@Suite struct RemotePathTests {
    @Test func normalizeEmptyAndRoot() throws {
        #expect(try RemotePath.normalize("") == "/")
        #expect(try RemotePath.normalize("/") == "/")
        #expect(try RemotePath.normalize("///") == "/")
    }

    @Test func normalizeCollapsesSeparatorsAndDots() throws {
        #expect(try RemotePath.normalize("a/b") == "/a/b")
        #expect(try RemotePath.normalize("/a//b/./c/") == "/a/b/c")
        #expect(try RemotePath.normalize("\\a\\b\\") == "/a/b")
    }

    @Test func normalizeRejectsTraversal() {
        #expect(throws: RemotePathError.traversal("/a/../b")) {
            try RemotePath.normalize("/a/../b")
        }
        #expect(throws: RemotePathError.self) {
            try RemotePath.normalize("..")
        }
    }

    @Test func normalizeKeepsUnicodeAndSpaces() throws {
        #expect(try RemotePath.normalize("/家庭 共享/假期.jpg") == "/家庭 共享/假期.jpg")
    }

    @Test func appendingValidName() throws {
        #expect(try RemotePath.appending("x.txt", to: "/") == "/x.txt")
        #expect(try RemotePath.appending("x.txt", to: "/a/b") == "/a/b/x.txt")
    }

    @Test func appendingRejectsInvalidNames() {
        for name in ["", ".", "..", "a/b", "a\\b", "a\u{0}b"] {
            #expect(throws: RemotePathError.self) {
                try RemotePath.appending(name, to: "/a")
            }
        }
    }

    @Test func parentAndFileName() {
        #expect(RemotePath.parent(of: "/a/b") == "/a")
        #expect(RemotePath.parent(of: "/a") == "/")
        #expect(RemotePath.parent(of: "/") == nil)
        #expect(RemotePath.fileName(of: "/a/b.txt") == "b.txt")
        #expect(RemotePath.fileName(of: "/") == "")
    }

    @Test func components() {
        #expect(RemotePath.components("/a/b/c") == ["a", "b", "c"])
        #expect(RemotePath.components("/") == [])
    }
}
