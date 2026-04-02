import Foundation

public struct FileItem: Identifiable, Hashable, Decodable, Sendable {
    public var id: String { path }
    public let name: String
    public let path: String
    public let size: Int64
    public let modTime: Date
    public let isDir: Bool
    public let mimeType: String?

    enum CodingKeys: String, CodingKey {
        case name = "Name"
        case path = "Path"
        case size = "Size"
        case modTime = "ModTime"
        case isDir = "IsDir"
        case mimeType = "MimeType"
    }
}

public struct Remote: Identifiable, Hashable, Sendable {
    public var id: String { name }
    public let name: String
    public let type: String

    public var displayName: String { name }

    public init(name: String, type: String) {
        self.name = name
        self.type = type
    }
}

public struct Location: Hashable, Sendable {
    public let fs: String
    public let path: String

    public init(fs: String, path: String) {
        self.fs = fs
        self.path = path
    }
}

public extension JSONDecoder {
    static let rclone: JSONDecoder = {
        let decoder = JSONDecoder()
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            if let date = formatter.date(from: dateString) {
                return date
            }
            let trimmed = dateString.replacingOccurrences(
                of: #"\.\d+Z$"#, with: "Z", options: .regularExpression
            )
            let basicFormatter = ISO8601DateFormatter()
            if let date = basicFormatter.date(from: trimmed) {
                return date
            }
            throw DecodingError.dataCorruptedError(
                in: container, debugDescription: "Invalid date: \(dateString)"
            )
        }
        return decoder
    }()
}
