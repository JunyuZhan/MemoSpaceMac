import Foundation
import Testing
@testable import MemoSpaceKit

@Suite struct SortTests {
    private func item(_ name: String, dir: Bool = false, size: Int64 = 0,
                      modified: Date = .distantPast) -> RemoteItem {
        RemoteItem(name: name, path: "/" + name, isDirectory: dir,
                   size: size, modified: modified, kind: dir ? .folder : .other)
    }

    @Test func foldersComeFirstAndNamesUseLocalizedOrder() {
        let items = [item("b.txt"), item("文件夹", dir: true), item("a.txt"), item("c.txt")]
        let sorted = ItemSorter.sorted(items, by: .name, order: .ascending)
        #expect(sorted.first?.isDirectory == true)
        #expect(sorted.dropFirst().map(\.name) == ["a.txt", "b.txt", "c.txt"])
    }

    @Test func sizeDescending() {
        let items = [item("small", size: 1), item("big", size: 100), item("mid", size: 10)]
        let sorted = ItemSorter.sorted(items, by: .size, order: .descending)
        #expect(sorted.map(\.name) == ["big", "mid", "small"])
    }

    @Test func missingDateSortsLast() {
        let dated = RemoteItem(name: "dated", path: "/dated", isDirectory: false, size: 0,
                               modified: Date(timeIntervalSince1970: 10), kind: .other)
        let undated = RemoteItem(name: "undated", path: "/undated", isDirectory: false, size: 0,
                                 modified: nil, kind: .other)
        let sorted = ItemSorter.sorted([undated, dated], by: .modified, order: .ascending)
        #expect(sorted.map(\.name) == ["dated", "undated"])
    }
}
