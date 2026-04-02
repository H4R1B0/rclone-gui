import Foundation
import RcloneKit
import TransferEngine

@Observable
public final class TransferViewModel {
    var activeTransfers: [TransferOperation] = []
    var completedTransfers: [TransferOperation] = []
    var failedTransfers: [TransferOperation] = []
    var isPanelExpanded: Bool = true

    private let manager: TransferManager
    private var pollingTask: Task<Void, Never>?

    init(client: RcloneClientProtocol) {
        self.manager = TransferManager(client: client)
    }

    func enqueue(_ operation: TransferOperation) async {
        await manager.enqueue(operation)
        await refreshFromManager()
    }

    func cancel(id: UUID) async {
        await manager.cancel(id: id)
        await refreshFromManager()
    }

    func clearCompleted() async {
        await manager.clearCompleted()
        await refreshFromManager()
    }

    @MainActor
    func startPolling() {
        pollingTask?.cancel()
        pollingTask = Task {
            while !Task.isCancelled {
                await refreshFromManager()
                try? await Task.sleep(for: .seconds(1))
            }
        }
    }

    func stopPolling() {
        pollingTask?.cancel()
        pollingTask = nil
    }

    @MainActor
    private func refreshFromManager() async {
        activeTransfers = await manager.activeTransfers
        completedTransfers = await manager.completedTransfers
        failedTransfers = await manager.failedTransfers
    }
}
