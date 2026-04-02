import Foundation
import RcloneKit

final class MockRcloneClient: RcloneClientProtocol, @unchecked Sendable {
    var responses: [String: [String: Any]] = [:]
    var callLog: [(method: String, params: [String: Any])] = []

    func call(_ method: String, params: [String: Any]) async throws -> [String: Any] {
        callLog.append((method, params))
        guard let response = responses[method] else {
            throw RcloneError.rpcFailed(method: method, status: 404, message: "Not mocked")
        }
        return response
    }
}
