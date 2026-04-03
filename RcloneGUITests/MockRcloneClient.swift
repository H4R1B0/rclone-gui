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
