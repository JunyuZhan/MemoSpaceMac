import Foundation

public enum SortKey: String, CaseIterable, Sendable {
    case name, size, modified, kind
}

public enum ItemSortOrder: String, Sendable {
    case ascending, descending
}

public enum ItemSorter {
    public static func sorted(_ items: [RemoteItem], by key: SortKey, order: ItemSortOrder) -> [RemoteItem] {
        items.sorted { lhs, rhs in
            if lhs.isDirectory != rhs.isDirectory { return lhs.isDirectory }
            let result: ComparisonResult
            switch key {
            case .name:
                result = lhs.name.localizedStandardCompare(rhs.name)
            case .size:
                result = compare(lhs.size, rhs.size)
            case .modified:
                result = compare(lhs.modified, rhs.modified)
            case .kind:
                result = compare(lhs.kind.rawValue, rhs.kind.rawValue)
            }
            if result == .orderedSame {
                return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
            }
            return order == .ascending ? result == .orderedAscending : result == .orderedDescending
        }
    }

    private static func compare<T: Comparable>(_ lhs: T, _ rhs: T) -> ComparisonResult {
        if lhs < rhs { return .orderedAscending }
        if lhs > rhs { return .orderedDescending }
        return .orderedSame
    }

    private static func compare<T: Comparable>(_ lhs: T?, _ rhs: T?) -> ComparisonResult {
        switch (lhs, rhs) {
        case let (l?, r?): return compare(l, r)
        case (nil, nil): return .orderedSame
        case (nil, _): return .orderedDescending
        case (_, nil): return .orderedAscending
        }
    }
}
