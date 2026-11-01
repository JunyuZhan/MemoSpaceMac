import Foundation
import Testing
@testable import MemoSpaceKit

@Suite struct NameConflictResolverTests {
    @Test func noConflictKeepsName() {
        #expect(NameConflictResolver.uniqueName(for: "a.txt", existing: []) == "a.txt")
    }

    @Test func appendsCounterBeforeExtension() {
        #expect(NameConflictResolver.uniqueName(for: "a.txt", existing: ["a.txt"]) == "a (1).txt")
    }

    @Test func skipsTakenCounters() {
        let existing: Set<String> = ["a.txt", "a (1).txt", "a (2).txt"]
        #expect(NameConflictResolver.uniqueName(for: "a.txt", existing: existing) == "a (3).txt")
    }

    @Test func handlesDirectoriesWithoutExtension() {
        #expect(NameConflictResolver.uniqueName(for: "照片", existing: ["照片"]) == "照片 (1)")
    }
}
