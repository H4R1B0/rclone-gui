import Foundation

public protocol RcloneClientProtocol: Sendable {
    func call(_ method: String, params: [String: Any]) async throws -> [String: Any]
}
