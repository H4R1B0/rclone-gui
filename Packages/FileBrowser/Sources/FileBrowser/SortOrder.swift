import Foundation
import RcloneKit

public enum FileSortOrder: String, CaseIterable, Sendable {
    case name
    case size
    case modTime

    public func sorted(_ files: [FileItem], ascending: Bool) -> [FileItem] {
        let dirs = files.filter(\.isDir).sorted { a, b in compare(a, b, ascending: ascending) }
        let nonDirs = files.filter { !$0.isDir }.sorted { a, b in compare(a, b, ascending: ascending) }
        return dirs + nonDirs
    }

    private func compare(_ a: FileItem, _ b: FileItem, ascending: Bool) -> Bool {
        let result: Bool
        switch self {
        case .name:
            result = a.name.localizedStandardCompare(b.name) == .orderedAscending
        case .size:
            result = a.size < b.size
        case .modTime:
            result = a.modTime < b.modTime
        }
        return ascending ? result : !result
    }
}
