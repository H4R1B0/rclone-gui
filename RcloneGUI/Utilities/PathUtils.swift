import Foundation

enum PathUtils {
    /// Join path parts, filtering empty, collapsing double slashes
    static func join(_ parts: String...) -> String {
        var joined = parts.filter { !$0.isEmpty }.joined(separator: "/")
        while joined.contains("//") {
            joined = joined.replacingOccurrences(of: "//", with: "/")
        }
        return joined
    }

    /// Get parent path (remove last segment)
    static func parent(_ path: String) -> String {
        var parts = path.split(separator: "/").map(String.init)
        guard !parts.isEmpty else { return "" }
        parts.removeLast()
        return parts.joined(separator: "/")
    }

    /// Get last path component (file/folder name)
    static func fileName(_ path: String) -> String {
        (path as NSString).lastPathComponent
    }

    /// Split path into breadcrumb segments
    static func segments(_ path: String) -> [String] {
        path.split(separator: "/").map(String.init)
    }

    /// Build path from segments up to index (for breadcrumb navigation)
    static func pathUpTo(segments: [String], index: Int) -> String {
        Array(segments.prefix(index + 1)).joined(separator: "/")
    }
}
