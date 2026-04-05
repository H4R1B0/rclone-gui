import Foundation
import RcloneKit

struct QueuedTransfer: Identifiable {
    let id = UUID()
    let name: String
    let isDir: Bool
    var children: [QueuedChild] = []
    var childrenLoaded: Bool = false
}

struct QueuedChild: Identifiable {
    let id = UUID()
    let name: String
    let path: String
    let size: Int64
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
    // Completed transfers (from core/transferred) — includes successful, failed, AND cancelled
    var completed: [RcloneCompletedTransfer] = []
    // Copy origins for restart (kept for cancelled/failed transfers)
    var copyOrigins: [String: CopyOrigin] = [:]
    // Active job IDs
    var jobIds: [Int] = []
    // Queued transfers waiting for a slot
    var queued: [QueuedTransfer] = []
    // Callback when transfer completes (dstFs to refresh)
    var onTransferComplete: ((String) -> Void)?

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

    // Checkpoints (resumable failed transfers)
    var checkpoints: [TransferCheckpoint] = []
    private let checkpointURL: URL
    private let maxRetries = AppConstants.maxTransferRetries

    private let client: RcloneClientProtocol
    private var pollingTask: Task<Void, Never>?
    private var isPolling = false
    private var completedKeys: Set<String> = []

    // MARK: - Computed

    var successfulCompleted: [RcloneCompletedTransfer] {
        completed.filter { $0.ok }
    }

    /// Real errors (not user-cancelled)
    var errorCompleted: [RcloneCompletedTransfer] {
        completed.filter { !$0.ok && !$0.isCancelled }
    }

    /// User-cancelled transfers (restartable)
    var cancelledCompleted: [RcloneCompletedTransfer] {
        completed.filter { $0.isCancelled }
    }

    var hasActiveTransfers: Bool {
        !transfers.isEmpty
    }

    /// Check if a completed transfer can be restarted (has origin info)
    func hasRestartInfo(for transfer: RcloneCompletedTransfer) -> Bool {
        copyOrigins[transfer.group] != nil || copyOrigins[transfer.name] != nil
    }

    init(client: RcloneClientProtocol, checkpointURL: URL? = nil) {
        self.client = client
        self.checkpointURL = checkpointURL ?? AppConstants.appSupportDir.appendingPathComponent(AppConstants.transferCheckpointsFile)
        loadCheckpoints()
    }

    // MARK: - Polling

    @MainActor
    func startPolling() {
        pollingTask?.cancel()
        pollingTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.poll()
                try? await Task.sleep(for: .seconds(AppConstants.transferPollingInterval))
            }
        }
    }

    func stopPolling() {
        pollingTask?.cancel()
        pollingTask = nil
    }

    @MainActor
    private func poll() async {
        guard !isPolling else { return }
        isPolling = true
        defer { isPolling = false }

        // 1. Get stats
        do {
            let stats = try await RcloneAPI.getStats(using: client)
            let newTransfers = stats.transferring ?? []
            let newNames = Set(newTransfers.map(\.name))

            if newTransfers.map(\.name) != transfers.map(\.name)
                || newTransfers.map(\.percentage) != transfers.map(\.percentage) {
                transfers = newTransfers
            }
            // Auto-dequeue items that now appear in active transfers or completed
            if !queued.isEmpty {
                let completedNames = Set(completed.map(\.name))
                queued.removeAll { q in newNames.contains(q.name) || completedNames.contains(q.name) }
            }
            totalSpeed = stats.speed
            totalBytes = stats.bytes
            totalSize = stats.totalBytes
            totalTransfers = stats.totalTransfers
            doneTransfers = stats.transfers
            errors = stats.errors

            // Extract lastError (skip "context canceled" — those are user cancellations)
            if let lastError = stats.lastError,
               !lastError.isEmpty,
               !lastError.contains("context canceled") {
                lastErrors.insert(lastError, at: 0)
                if lastErrors.count > AppConstants.maxErrorHistory {
                    lastErrors = Array(lastErrors.prefix(AppConstants.maxErrorHistory))
                }
            }
        } catch {
            #if DEBUG
            print("[RcloneGUI] Stats poll error: \(error.localizedDescription)")
            #endif
        }

        // 2. Get completed transfers — cancelled, failed, and successful all go to completed list
        do {
            let transferred = try await RcloneAPI.getTransferred(using: client)
            for item in transferred {
                let key = "\(item.name)-\(item.completed_at)"
                if !completedKeys.contains(key) {
                    completedKeys.insert(key)
                    completed.insert(item, at: 0)

                    if item.isCancelled {
                        // User-cancelled: keep copyOrigins for restart capability
                    } else if item.ok {
                        // Success: notify destination panel to refresh
                        if let origin = copyOrigins[item.group] ?? copyOrigins[item.name] {
                            onTransferComplete?(origin.dstFs)
                        }
                        // Clean up origins for successful transfers
                        copyOrigins.removeValue(forKey: item.group)
                        copyOrigins.removeValue(forKey: item.name)
                    } else {
                        // Real error: auto-checkpoint for retry
                        if let origin = copyOrigins[item.group] ?? copyOrigins[item.name] {
                            let cp = TransferCheckpoint(
                                fileName: item.name,
                                srcFs: origin.srcFs, srcRemote: origin.srcRemote,
                                dstFs: origin.dstFs, dstRemote: origin.dstRemote,
                                isDir: origin.isDir, totalSize: item.size
                            )
                            addCheckpoint(cp)
                        }
                        // Keep copyOrigins for restart capability
                    }
                }
            }
            if completed.count > AppConstants.maxCompletedTransfers {
                completed = Array(completed.prefix(AppConstants.maxCompletedTransfers))
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
        paused = true
        do {
            // rate "1" = 1 byte/sec, effectively pauses (rate "0" means unlimited in rclone)
            try await RcloneAPI.setBwLimit(using: client, rate: "1")
        } catch {
            paused = false
            #if DEBUG
            print("[RcloneGUI] pauseAll failed: \(error.localizedDescription)")
            #endif
        }
    }

    @MainActor
    func resumeAll() async {
        paused = false
        do {
            try await RcloneAPI.setBwLimit(using: client, rate: "off")
        } catch {
            paused = true
            #if DEBUG
            print("[RcloneGUI] resumeAll failed: \(error.localizedDescription)")
            #endif
        }
    }

    /// Stop all active transfers + clear queue
    @MainActor
    func stopAllJobs() async {
        queued.removeAll()
        for jobId in jobIds {
            try? await RcloneAPI.stopJob(using: client, jobid: jobId)
        }
    }

    /// Cancel everything: stop active jobs, clear queue, resume bandwidth
    /// Active transfers are immediately moved to cancelled list (optimistic update)
    @MainActor
    func cancelAll() async {
        // 1. Optimistic update: move active transfers to cancelled list immediately
        let now = ISO8601DateFormatter().string(from: Date())
        for t in transfers {
            let key = "\(t.name)-\(now)"
            if !completedKeys.contains(key) {
                completedKeys.insert(key)
                let cancelled = RcloneCompletedTransfer(from: [
                    "name": t.name, "size": t.size, "bytes": t.bytes,
                    "error": "context canceled", "group": t.group,
                    "completed_at": now
                ])
                completed.insert(cancelled, at: 0)
            }
        }
        transfers.removeAll()
        queued.removeAll()

        // 2. Stop all jobs in background
        for jobId in jobIds {
            try? await RcloneAPI.stopJob(using: client, jobid: jobId)
        }
        jobIds.removeAll()

        // 3. Resume bandwidth if paused
        if paused {
            await resumeAll()
        }
    }

    @MainActor
    func stopJob(id: Int) async {
        try? await RcloneAPI.stopJob(using: client, jobid: id)
    }

    /// Find job ID for a transfer by checking all known mappings
    func findJobId(for transfer: RcloneTransferring) -> Int? {
        // 1. Check if group directly matches "job/N"
        if transfer.group.hasPrefix("job/"), let id = Int(transfer.group.dropFirst(4)) {
            return id
        }
        // 2. Search copyOrigins for a "job/N" key whose origin matches by name
        for (key, val) in copyOrigins where key.hasPrefix("job/") {
            let srcFileName = (val.srcRemote as NSString).lastPathComponent
            if transfer.name == srcFileName || transfer.name == val.srcRemote || transfer.name == val.dstRemote {
                if let id = Int(key.dropFirst(4)) { return id }
            }
        }
        // 3. Check if any jobId is directly stored by transfer name
        if copyOrigins[transfer.name] != nil {
            for (key, val) in copyOrigins where key.hasPrefix("job/") {
                if let origin = copyOrigins[transfer.name],
                   val.srcFs == origin.srcFs && val.srcRemote == origin.srcRemote {
                    if let id = Int(key.dropFirst(4)) { return id }
                }
            }
        }
        return nil
    }

    /// Cancel a specific transfer
    @MainActor
    func cancelTransfer(_ transfer: RcloneTransferring) async {
        if let jobId = findJobId(for: transfer) {
            await stopJob(id: jobId)
        } else {
            #if DEBUG
            print("[RcloneGUI] cancelTransfer: could not find jobId for \(transfer.name)")
            #endif
        }
    }

    // MARK: - Copy Origins (for restart)

    func addCopyOrigin(group: String, origin: CopyOrigin) {
        copyOrigins[group] = origin
    }

    /// Restart a failed or cancelled transfer using stored origin info
    @MainActor
    func restartFailed(_ transfer: RcloneCompletedTransfer) async {
        guard let origin = copyOrigins[transfer.group] ?? copyOrigins[transfer.name] else { return }

        // Re-register origins before API call
        addCopyOrigin(group: transfer.name, origin: origin)
        addCopyOrigin(group: origin.srcRemote, origin: origin)

        do {
            let jobId: Int
            if origin.isDir {
                jobId = try await RcloneAPI.copyDir(using: client, srcFs: origin.srcFs, srcRemote: origin.srcRemote, dstFs: origin.dstFs, dstRemote: origin.dstRemote)
            } else {
                jobId = try await RcloneAPI.copyFileAsync(using: client, srcFs: origin.srcFs, srcRemote: origin.srcRemote, dstFs: origin.dstFs, dstRemote: origin.dstRemote)
            }
            addCopyOrigin(group: "job/\(jobId)", origin: origin)
            // Remove the old completed entry
            removeCompleted(name: transfer.name, completedAt: transfer.completed_at)
        } catch {
            // Clean up pre-registered origins on failure
            copyOrigins.removeValue(forKey: transfer.name)
            copyOrigins.removeValue(forKey: origin.srcRemote)
            print("[RcloneGUI] restartFailed failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Checkpoint Management (Resume)

    func addCheckpoint(_ cp: TransferCheckpoint) {
        checkpoints.append(cp)
        saveCheckpoints()
    }

    func removeCheckpoint(id: UUID) {
        checkpoints.removeAll { $0.id == id }
        saveCheckpoints()
    }

    @MainActor
    func retryCheckpoint(_ cp: TransferCheckpoint) async {
        guard cp.attempts < maxRetries else { return }
        var updated = cp
        updated.attempts += 1
        updated.lastAttempt = Date()

        do {
            if cp.isDir {
                _ = try await RcloneAPI.copyDir(using: client, srcFs: cp.srcFs, srcRemote: cp.srcRemote, dstFs: cp.dstFs, dstRemote: cp.dstRemote)
            } else {
                _ = try await RcloneAPI.copyFileAsync(using: client, srcFs: cp.srcFs, srcRemote: cp.srcRemote, dstFs: cp.dstFs, dstRemote: cp.dstRemote)
            }
            removeCheckpoint(id: cp.id)
        } catch {
            updated.lastError = error.localizedDescription
            if let idx = checkpoints.firstIndex(where: { $0.id == cp.id }) {
                checkpoints[idx] = updated
            }
            saveCheckpoints()
        }
    }

    @MainActor
    func retryAllFailed() async {
        let retryable = checkpoints.filter { $0.attempts < maxRetries }
        for cp in retryable {
            await retryCheckpoint(cp)
        }
    }

    func saveCheckpoints() {
        if let data = try? JSONEncoder().encode(checkpoints) {
            try? data.write(to: checkpointURL)
        }
    }

    func loadCheckpoints() {
        guard let data = try? Data(contentsOf: checkpointURL),
              let loaded = try? JSONDecoder().decode([TransferCheckpoint].self, from: data)
        else { return }
        checkpoints = loaded
    }

    // MARK: - Queue Management

    func enqueue(_ item: QueuedTransfer) {
        queued.append(item)
    }

    /// Load children for a queued folder transfer
    @MainActor
    func loadQueuedChildren(name: String, fs: String, path: String) async {
        guard let idx = queued.firstIndex(where: { $0.name == name && $0.isDir && !$0.childrenLoaded }) else { return }
        do {
            let result = try await client.call("operations/list", params: [
                "fs": fs, "remote": path, "opt": ["recurse": true]
            ])
            guard let list = result["list"] as? [[String: Any]] else { return }
            let children: [QueuedChild] = list.compactMap { item in
                guard let itemName = item["Name"] as? String,
                      let itemPath = item["Path"] as? String,
                      let isDir = item["IsDir"] as? Bool,
                      !isDir else { return nil }
                let size = item["Size"] as? Int64 ?? 0
                return QueuedChild(name: itemName, path: itemPath, size: size, isDir: false)
            }
            if queued.indices.contains(idx) {
                queued[idx].children = children
                queued[idx].childrenLoaded = true
            }
        } catch {
            #if DEBUG
            print("[RcloneGUI] loadQueuedChildren error: \(error.localizedDescription)")
            #endif
        }
    }

    func dequeue(name: String) {
        queued.removeAll { $0.name == name }
    }

    func removeCompleted(name: String, completedAt: String) {
        let key = "\(name)-\(completedAt)"
        completed.removeAll { "\($0.name)-\($0.completed_at)" == key }
        completedKeys.remove(key)
    }

    // MARK: - History Management

    func clearCompleted() {
        let keysToRemove = completed.filter { $0.ok }.map { "\($0.name)-\($0.completed_at)" }
        completed.removeAll { $0.ok }
        for key in keysToRemove { completedKeys.remove(key) }
    }

    func clearErrors() {
        let keysToRemove = completed.filter { !$0.ok }.map { "\($0.name)-\($0.completed_at)" }
        completed.removeAll { !$0.ok }
        for key in keysToRemove { completedKeys.remove(key) }
        lastErrors.removeAll()
    }

    /// Clear completed/failed/cancelled items — keeps active and queued
    func clearInactive() {
        completed.removeAll()
        lastErrors.removeAll()
    }

    @MainActor
    func clearAll() async {
        completed.removeAll()
        lastErrors.removeAll()
        copyOrigins.removeAll()
        queued.removeAll()
        checkpoints.removeAll()
        saveCheckpoints()
        // Reset rclone stats BEFORE clearing completedKeys to avoid re-add race
        try? await RcloneAPI.resetStats(using: client)
        completedKeys.removeAll()
    }

    var hasInactiveItems: Bool {
        !completed.isEmpty
    }
}
