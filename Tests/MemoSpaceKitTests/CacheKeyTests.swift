import Foundation
import Testing
@testable import MemoSpaceKit

@Suite struct CacheKeyTests {
    @Test func stableAndHex() {
        let date = Date(timeIntervalSince1970: 100)
        let key = CacheKey.make(path: "/a.jpg", size: 10, modified: date)
        #expect(key == CacheKey.make(path: "/a.jpg", size: 10, modified: date))
        #expect(key.count == 64)
        #expect(key.allSatisfy { $0.isHexDigit })
    }

    @Test func changesWithAnyInput() {
        let date = Date(timeIntervalSince1970: 100)
        let base = CacheKey.make(path: "/a.jpg", size: 10, modified: date)
        #expect(base != CacheKey.make(path: "/b.jpg", size: 10, modified: date))
        #expect(base != CacheKey.make(path: "/a.jpg", size: 11, modified: date))
        #expect(base != CacheKey.make(path: "/a.jpg", size: 10, modified: date.addingTimeInterval(1)))
        #expect(base != CacheKey.make(path: "/a.jpg", size: 10, modified: nil))
    }
}
