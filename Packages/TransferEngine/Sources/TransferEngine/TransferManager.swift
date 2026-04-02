import Foundation
import RcloneKit

public actor TransferManager {
    private let client: RcloneClientProtocol
    private var transfers: [UUID: TransferOperation] = [:]
    private let maxConcurrent: Int
    private var runningCount = 0

    public init(client: RcloneClientProtocol, maxConcurrent: Int = 3) {
        self.client = client
        self.maxConcurrent = maxConcurrent
    }

    public var allTransfers: [TransferOperation] {
        Array(transfers.values).sorted { $0.createdAt > $1.createdAt }
    }

    public var activeTransfers: [TransferOperation] {
        transfers.values.filter { !$0.status.isTerminal }
            .sorted { $0.createdAt > $1.createdAt }
    }

    public var completedTransfers: [TransferOperation] {
        transfers.values.filter { $0.status == .completed }
            .sorted { $0.createdAt > $1.createdAt }
    }

    public var failedTransfers: [TransferOperation] {
        transfers.values.filter {
            if case .failed = $0.status { return true }
            return false
        }.sorted { $0.createdAt > $1.createdAt }
    }

    public func enqueue(_ operation: TransferOperation) {
        transfers[operation.id] = operation

        Task {
            await execute(id: operation.id)
        }
    }

    private func execute(id: UUID) async {
        guard var op = transfers[id] else { return }

        op.status = .transferring
        transfers[id] = op
        runningCount += 1

        do {
            switch op.kind {
            case .copy:
                try await RcloneAPI.copyFile(
                    using: client,
                    srcFs: op.source.fs, srcRemote: op.source.path,
                    dstFs: op.destination.fs, dstRemote: op.destination.path
                )
            case .move:
                try await RcloneAPI.moveFile(
                    using: client,
                    srcFs: op.source.fs, srcRemote: op.source.path,
                    dstFs: op.destination.fs, dstRemote: op.destination.path
                )
            }
            op.status = .completed
            op.progress = 1.0
        } catch {
            op.status = .failed(message: error.localizedDescription)
        }

        transfers[id] = op
        runningCount -= 1
    }

    public func cancel(id: UUID) {
        guard var op = transfers[id], !op.status.isTerminal else { return }
        op.status = .failed(message: "Cancelled by user")
        transfers[id] = op
    }

    public func clearCompleted() {
        for (id, op) in transfers where op.status.isTerminal {
            transfers.removeValue(forKey: id)
        }
    }
}
