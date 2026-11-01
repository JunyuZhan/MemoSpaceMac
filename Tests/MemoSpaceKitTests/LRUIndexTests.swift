import Foundation
import Testing
@testable import MemoSpaceKit

@Suite struct LRUIndexTests {
    @Test func insertUpdatesTotalSize() {
        var index = LRUIndex()
        index.insert(key: "a", size: 10, at: Date(timeIntervalSince1970: 1))
        index.insert(key: "b", size: 20, at: Date(timeIntervalSince1970: 2))
        index.insert(key: "a", size: 15, at: Date(timeIntervalSince1970: 3))
        #expect(index.totalSize == 35)
        #expect(index.entries.count == 2)
    }

    @Test func evictionPicksLeastRecentlyUsed() {
        var index = LRUIndex()
        index.insert(key: "a", size: 10, at: Date(timeIntervalSince1970: 1))
        index.insert(key: "b", size: 10, at: Date(timeIntervalSince1970: 2))
        index.insert(key: "c", size: 10, at: Date(timeIntervalSince1970: 3))
        index.touch(key: "a", at: Date(timeIntervalSince1970: 4))

        #expect(index.evictionCandidates(toFit: 25) == ["b"])
        #expect(index.evictionCandidates(toFit: 15) == ["b", "c"])
        #expect(index.evictionCandidates(toFit: 30) == [])
    }

    @Test func removeUpdatesTotalSize() {
        var index = LRUIndex()
        index.insert(key: "a", size: 10)
        index.remove(key: "a")
        #expect(index.totalSize == 0)
        #expect(index.entries.isEmpty)
    }
}
