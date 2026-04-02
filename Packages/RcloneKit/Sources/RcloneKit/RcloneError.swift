import Foundation

public enum RcloneError: LocalizedError, Equatable {
    case notInitialized
    case rpcFailed(method: String, status: Int, message: String)
    case remoteNotFound(String)
    case pathNotFound(String)
    case permissionDenied(String)
    case transferFailed(reason: String)
    case encodingFailed
    case decodingFailed(String)

    public var errorDescription: String? {
        switch self {
        case .notInitialized:
            return "RcloneClient is not initialized. Call initialize() first."
        case .rpcFailed(let method, let status, let message):
            return "RPC '\(method)' failed (status \(status)): \(message)"
        case .remoteNotFound(let name):
            return "Remote not found: \(name)"
        case .pathNotFound(let path):
            return "Path not found: \(path)"
        case .permissionDenied(let detail):
            return "Permission denied: \(detail)"
        case .transferFailed(let reason):
            return "Transfer failed: \(reason)"
        case .encodingFailed:
            return "Failed to encode JSON parameters"
        case .decodingFailed(let detail):
            return "Failed to decode response: \(detail)"
        }
    }
}
