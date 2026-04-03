import Foundation
import RcloneKit

struct StoppedTransfer: Identifiable {
    let id = UUID()
    let name: String
    let group: String
    let size: Int64
    let srcFs: String?
    let srcRemote: String?
    let dstFs: String?
    let dstRemote: String?
    let isDir: Bool
}

struct CopyOrigin {
    let srcFs: String
    let srcRemote: String
    let dstFs: String
    let dstRemote: String
    let isDir: Bool
}

@Observable
final class TransferViewModel {
    // Active transfers (from stats.transferring)
    var transfers: [RcloneTransferring] = []
    // Completed transfers (from core/transferred)
    var completed: [RcloneCompletedTransfer] = []
    // Manually stopped transfers (restartable)
    var stopped: [StoppedTransfer] = []
    // Copy origins for restart
    var copyOrigins: [String: CopyOrigin] = [:]
    // Active job IDs
    var jobIds: [Int] = []

    // Aggregate stats
    var totalSpeed: Double = 0
    var totalBytes: Int64 = 0
    var totalSize: Int64 = 0
    var totalTransfers: Int = 0
    var doneTransfers: Int = 0
    var errors: Int = 0
    var lastErrors: [String] = []

    // Pause state
    var paused: Bool = false

    private let client: RcloneClientProtocol
    private var pollingTask: Task<Void, Never>?
    private var completedKeys: Set<String> = []

    // Computed
    var successfulCompleted: [RcloneCompletedTransfer] {
        completed.filter { $0.ok }
    }

    var errorCompleted: [RcloneCompletedTransfer] {
        completed.filter { !$0.ok }
    }

    var hasActiveTransfers: Bool {
        !transfers.isEmpty
    }

    init(client: RcloneClientProtocol) {
        self.client = client
    }

    // MARK: - Polling (matches TypeScript useTransferPolling)

    @MainActor
    func startPolling() {
        pollingTask?.cancel()
        pollingTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.poll()
                try? await Task.sleep(for: .seconds(1))
            }
        }
    }

    func stopPolling() {
        pollingTask?.cancel()
        pollingTask = nil
    }

    @MainActor
    private func poll() async {
        // 1. Get stats
        do {
            let stats = try await RcloneAPI.getStats(using: client)
            transfers = stats.transferring ?? []
            totalSpeed = stats.speed
            totalBytes = stats.bytes
            totalSize = stats.totalBytes
            totalTransfers = stats.totalTransfers
            doneTransfers = stats.transfers
            errors = stats.errors

            // Extract lastError (skip "context canceled" — those are manual stops)
            if let lastError = stats.lastError,
               !lastError.isEmpty,
               !lastError.contains("context canceled") {
                lastErrors.insert(lastError, at: 0)
                if lastErrors.count > 100 {
                    lastErrors = Array(lastErrors.prefix(100))
                }
            }
        } catch {
            #if DEBUG
            print("[RcloneGUI] Stats poll error: \(error.localizedDescription)")
            #endif
        }

        // 2. Get completed transfers
        do {
            let transferred = try await RcloneAPI.getTransferred(using: client)
            for item in transferred {
                let key = "\(item.name)-\(item.completed_at)"
                if !completedKeys.contains(key) {
                    completedKeys.insert(key)
                    // Skip "context canceled" — those go to stopped, not completed
                    if !item.error.contains("context canceled") {
                        completed.insert(item, at: 0)
                    }
                }
            }
            // Cap at 200
            if completed.count > 200 {
                completed = Array(completed.prefix(200))
            }
        } catch {
            #if DEBUG
            print("[RcloneGUI] Transferred fetch error: \(error.localizedDescription)")
            #endif
        }

        // 3. Get job list
        do {
            jobIds = try await RcloneAPI.getJobList(using: client)
        } catch {
            #if DEBUG
            print("[RcloneGUI] Job list fetch error: \(error.localizedDescription)")
            #endif
        }
    }

    // MARK: - Transfer Control

    @MainActor
    func pauseAll() async {
        do {
            try await RcloneAPI.setBwLimit(using: client, rate: "1")
            paused = true
        } catch {
            print("[RcloneGUI] pauseAll failed: \(error.localizedDescription)")
        }
    }

    @MainActor
    func resumeAll() async {
        do {
            try await RcloneAPI.setBwLimit(using: client, rate: "off")
            paused = false
        } catch {
            print("[RcloneGUI] resumeAll failed: \(error.localizedDescription)")
        }
    }

    @MainActor
    func stopAllJobs() async {
        for jobId in jobIds {
            try? await RcloneAPI.stopJob(using: client, jobid: jobId)
        }
    }

    @MainActor
    func stopJob(id: Int) async {
        try? await RcloneAPI.stopJob(using: client, jobid: id)
    }

    // MARK: - Copy Origins (for restart)

    func addCopyOrigin(group: String, origin: CopyOrigin) {
        copyOrigins[group] = origin
    }

    @MainActor
    func restartTransfer(_ transfer: StoppedTransfer) async {
        guard let srcFs = transfer.srcFs,
              let srcRemote = transfer.srcRemote,
              let dstFs = transfer.dstFs,
              let dstRemote = transfer.dstRemote else { return }

        do {
            if transfer.isDir {
                _ = try await RcloneAPI.copyDir(using: client, srcFs: srcFs, srcRemote: srcRemote, dstFs: dstFs, dstRemote: dstRemote)
            } else {
                _ = try await RcloneAPI.copyFileAsync(using: client, srcFs: srcFs, srcRemote: srcRemote, dstFs: dstFs, dstRemote: dstRemote)
            }
            // Remove from stopped
            stopped.removeAll { $0.id == transfer.id }
        } catch {
            print("[RcloneGUI] restartTransfer failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Stopped Management

    func addStopped(_ item: StoppedTransfer) {
        stopped.insert(item, at: 0)
    }

    func removeStopped(id: UUID) {
        stopped.removeAll { $0.id == id }
    }

    // MARK: - History Management

    func clearCompleted() {
        completed.removeAll { $0.ok }
    }

    func clearErrors() {
        completed.removeAll { !$0.ok }
        lastErrors.removeAll()
    }

    func clearStopped() {
        stopped.removeAll()
    }

    func clearAll() {
        completed.removeAll()
        stopped.removeAll()
        lastErrors.removeAll()
        completedKeys.removeAll()
    }
}
