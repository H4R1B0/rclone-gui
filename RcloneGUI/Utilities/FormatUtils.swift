import Foundation

enum FormatUtils {
    /// Format bytes to human readable (e.g., 1572864 → "1.5 MB")
    static func formatBytes(_ bytes: Int64) -> String {
        let units = ["B", "KB", "MB", "GB", "TB", "PB"]
        var size = Double(bytes)
        var unitIndex = 0
        while size >= 1024 && unitIndex < units.count - 1 {
            size /= 1024
            unitIndex += 1
        }
        if unitIndex == 0 {
            return "\(bytes) B"
        }
        return String(format: "%.1f %@", size, units[unitIndex])
    }

    /// Format speed (e.g., 1048576 → "1.0 MB/s")
    static func formatSpeed(_ bytesPerSec: Double) -> String {
        return "\(formatBytes(Int64(bytesPerSec)))/s"
    }

    /// Format ETA seconds to human readable
    static func formatEta(_ seconds: Double) -> String {
        guard seconds > 0 && !seconds.isNaN && !seconds.isInfinite else { return "-" }
        let s = Int(seconds)
        if s < 60 { return "\(s)s" }
        if s < 3600 { return "\(s / 60)m \(s % 60)s" }
        return "\(s / 3600)h \(s % 3600 / 60)m"
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm"
        f.locale = Locale(identifier: "\(AppConstants.defaultLocale)-KR")
        return f
    }()

    /// Format Date to "YYYY-MM-DD HH:MM"
    static func formatDate(_ date: Date) -> String {
        dateFormatter.string(from: date)
    }

    /// Get SF Symbol name for file type (matches TypeScript getFileIcon)
    static func fileIcon(name: String, isDir: Bool) -> String {
        if isDir { return "folder.fill" }
        let ext = (name as NSString).pathExtension.lowercased()
        switch ext {
        case "jpg", "jpeg", "png", "gif", "svg", "webp", "bmp", "ico", "tiff":
            return "photo"
        case "mp4", "mkv", "avi", "mov", "webm", "flv", "wmv":
            return "film"
        case "mp3", "wav", "flac", "aac", "ogg", "wma", "m4a":
            return "music.note"
        case "pdf":
            return "doc.richtext"
        case "doc", "docx", "xls", "xlsx", "ppt", "pptx", "txt", "rtf", "csv":
            return "doc.text"
        case "zip", "rar", "7z", "tar", "gz", "bz2", "xz":
            return "doc.zipper"
        case "js", "ts", "py", "go", "java", "swift", "c", "cpp", "h", "rs",
             "html", "css", "json", "yaml", "yml", "xml", "toml", "sh":
            return "chevron.left.forwardslash.chevron.right"
        default:
            return "doc"
        }
    }
}
