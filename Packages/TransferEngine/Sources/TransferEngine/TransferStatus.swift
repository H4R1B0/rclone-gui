import Foundation

public enum TransferStatus: Equatable, Sendable {
    case pending
    case transferring
    case paused
    case completed
    case failed(message: String)

    public var isTerminal: Bool {
        switch self {
        case .completed, .failed: return true
        default: return false
        }
    }
}

public enum TransferKind: String, Sendable {
    case copy
    case move
}
