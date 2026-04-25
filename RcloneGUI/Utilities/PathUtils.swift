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

    /// Get parent path (remove last segment).
    /// 절대 경로(`/foo/bar`)는 leading `/`를 보존하여 `/foo`를, 상대 경로는 leading slash 없이 반환.
    /// 이미 루트(`/` 또는 빈 문자열)인 경우 같은 값을 반환.
    static func parent(_ path: String) -> String {
        let absolute = path.hasPrefix("/")
        var parts = path.split(separator: "/").map(String.init)
        guard !parts.isEmpty else { return absolute ? "/" : "" }
        parts.removeLast()
        let joined = parts.joined(separator: "/")
        if absolute {
            return parts.isEmpty ? "/" : "/\(joined)"
        }
        return joined
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
    /// If the original path started with "/", the result preserves the leading slash
    static func pathUpTo(segments: [String], index: Int, absolute: Bool = false) -> String {
        let joined = Array(segments.prefix(index + 1)).joined(separator: "/")
        return absolute ? "/\(joined)" : joined
    }
}
