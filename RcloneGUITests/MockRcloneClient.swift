import Foundation
import RcloneKit

final class MockRcloneClient: RcloneClientProtocol, @unchecked Sendable {
    var responses: [String: [String: Any]] = [:]
    var callLog: [(method: String, params: [String: Any])] = []
    var errorForMethod: [String: Error] = [:]

    func call(_ method: String, params: [String: Any]) async throws -> [String: Any] {
        callLog.append((method, params))
        if let error = errorForMethod[method] { throw error }
        guard let response = responses[method] else {
            throw RcloneError.rpcFailed(method: method, status: 404, message: "Not mocked")
        }
        return response
    }

    func reset() {
        responses.removeAll()
        callLog.removeAll()
        errorForMethod.removeAll()
    }
}

// MARK: - Test Helpers

/// Create a FileItem for testing via JSON decoding
func makeFileItem(name: String, path: String? = nil, size: Int64 = 0, isDir: Bool = false) -> FileItem {
    let p = path ?? name
    let json: [String: Any] = [
        "Name": name, "Path": p, "Size": size, "IsDir": isDir,
        "ModTime": "2024-01-01T00:00:00.000000000Z", "MimeType": ""
    ]
    let data = try! JSONSerialization.data(withJSONObject: json)
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .custom { decoder in
        let container = try decoder.singleValueContainer()
        let str = try container.decode(String.self)
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return fmt.date(from: str) ?? Date()
    }
    return try! decoder.decode(FileItem.self, from: data)
}
