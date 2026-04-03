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

// MARK: - Transfer Stats

public struct RcloneStats: Sendable {
    public let bytes: Int64
    public let speed: Double
    public let totalBytes: Int64
    public let totalTransfers: Int
    public let transfers: Int
    public let errors: Int
    public let lastError: String?
    public let eta: Double?
    public let transferring: [RcloneTransferring]?

    public init(from dict: [String: Any]) {
        self.bytes = dict["bytes"] as? Int64 ?? 0
        self.speed = dict["speed"] as? Double ?? 0
        self.totalBytes = dict["totalBytes"] as? Int64 ?? 0
        self.totalTransfers = dict["totalTransfers"] as? Int ?? 0
        self.transfers = dict["transfers"] as? Int ?? 0
        self.errors = dict["errors"] as? Int ?? 0
        self.lastError = dict["lastError"] as? String
        self.eta = dict["eta"] as? Double
        if let transferringList = dict["transferring"] as? [[String: Any]] {
            self.transferring = transferringList.map { RcloneTransferring(from: $0) }
        } else {
            self.transferring = nil
        }
    }
}

public struct RcloneTransferring: Identifiable, Sendable {
    public var id: String { "\(group)/\(name)" }
    public let name: String
    public let size: Int64
    public let bytes: Int64
    public let percentage: Int
    public let speed: Double
    public let speedAvg: Double
    public let eta: Double
    public let group: String

    public init(from dict: [String: Any]) {
        self.name = dict["name"] as? String ?? ""
        self.size = dict["size"] as? Int64 ?? 0
        self.bytes = dict["bytes"] as? Int64 ?? 0
        self.percentage = dict["percentage"] as? Int ?? 0
        self.speed = dict["speed"] as? Double ?? 0
        self.speedAvg = dict["speedAvg"] as? Double ?? 0
        self.eta = dict["eta"] as? Double ?? 0
        self.group = dict["group"] as? String ?? ""
    }
}

public struct RcloneCompletedTransfer: Identifiable, Sendable {
    public var id: String { "\(name)-\(completed_at)" }
    public let name: String
    public let size: Int64
    public let bytes: Int64
    public let error: String
    public let group: String
    public let completed_at: String

    public var ok: Bool { error.isEmpty }

    public init(from dict: [String: Any]) {
        self.name = dict["name"] as? String ?? ""
        self.size = dict["size"] as? Int64 ?? 0
        self.bytes = dict["bytes"] as? Int64 ?? 0
        self.error = dict["error"] as? String ?? ""
        self.group = dict["group"] as? String ?? ""
        self.completed_at = dict["completed_at"] as? String ?? ""
    }
}

public struct RcloneJobStatus: Sendable {
    public let id: Int
    public let group: String
    public let finished: Bool
    public let success: Bool
    public let error: String
    public let duration: Double
    public let startTime: String
    public let endTime: String

    public init(from dict: [String: Any]) {
        self.id = dict["id"] as? Int ?? 0
        self.group = dict["group"] as? String ?? ""
        self.finished = dict["finished"] as? Bool ?? false
        self.success = dict["success"] as? Bool ?? false
        self.error = dict["error"] as? String ?? ""
        self.duration = dict["duration"] as? Double ?? 0
        self.startTime = dict["startTime"] as? String ?? ""
        self.endTime = dict["endTime"] as? String ?? ""
    }
}

// MARK: - Provider

public struct RcloneProvider: Identifiable, Sendable {
    public var id: String { prefix }
    public let name: String
    public let description: String
    public let prefix: String
    public let options: [ProviderOption]

    public init(from dict: [String: Any]) {
        self.name = dict["Name"] as? String ?? ""
        self.description = dict["Description"] as? String ?? ""
        self.prefix = dict["Prefix"] as? String ?? ""
        if let opts = dict["Options"] as? [[String: Any]] {
            self.options = opts.map { ProviderOption(from: $0) }
        } else {
            self.options = []
        }
    }
}

public struct ProviderOption: Sendable {
    public let name: String
    public let help: String
    public let defaultValue: String
    public let required: Bool
    public let isPassword: Bool
    public let hide: Int
    public let advanced: Bool

    public init(from dict: [String: Any]) {
        self.name = dict["Name"] as? String ?? ""
        self.help = dict["Help"] as? String ?? ""
        if let def = dict["Default"] {
            self.defaultValue = "\(def)"
        } else {
            self.defaultValue = ""
        }
        self.required = dict["Required"] as? Bool ?? false
        self.isPassword = dict["IsPassword"] as? Bool ?? false
        self.hide = dict["Hide"] as? Int ?? 0
        self.advanced = dict["Advanced"] as? Bool ?? false
    }

    public var isVisible: Bool { hide == 0 }
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
