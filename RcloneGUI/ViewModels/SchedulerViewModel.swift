import Foundation

struct ScheduledTask: Identifiable, Codable {
    let id: UUID
    var profileId: UUID  // SyncProfile id
    var profileName: String
    var interval: TimeInterval  // seconds
    var enabled: Bool
    var lastRun: Date?
    var nextRun: Date?

    init(profileId: UUID, profileName: String, interval: TimeInterval) {
        self.id = UUID()
        self.profileId = profileId
        self.profileName = profileName
        self.interval = interval
        self.enabled = true
        self.lastRun = nil
        self.nextRun = Date().addingTimeInterval(interval)
    }

    var intervalLabel: String {
        if interval < 3600 { return "\(Int(interval / 60))\(L10n.t("scheduler.minutes"))" }
        if interval < 86400 { return "\(Int(interval / 3600))\(L10n.t("scheduler.hours"))" }
        return "\(Int(interval / 86400))\(L10n.t("scheduler.days"))"
    }
}

@Observable
final class SchedulerViewModel {
    var tasks: [ScheduledTask] = []
    var logs: [String] = []

    private var monitorTask: Task<Void, Never>?
    private let configURL: URL
    private let logsURL: URL

    init(configURL: URL? = nil, logsURL: URL? = nil) {
        self.configURL = configURL ?? AppConstants.appSupportDir.appendingPathComponent(AppConstants.schedulerFile)
        self.logsURL = logsURL ?? AppConstants.appSupportDir.appendingPathComponent(AppConstants.schedulerLogsFile)
        loadTasks()
        loadLogs()
    }

    func startMonitoring() {
        stopMonitoring()
        let scheduler = self
        monitorTask = Task {
            while !Task.isCancelled {
                _ = await MainActor.run { scheduler.checkAndRun() }
                try? await Task.sleep(for: .seconds(AppConstants.schedulerMonitoringInterval))
            }
        }
    }

    func stopMonitoring() {
        monitorTask?.cancel()
        monitorTask = nil
    }

    deinit {
        monitorTask?.cancel()
    }

    func addTask(_ task: ScheduledTask) {
        tasks.append(task)
        saveTasks()
    }

    func removeTask(id: UUID) {
        tasks.removeAll { $0.id == id }
        saveTasks()
    }

    func toggleTask(id: UUID) {
        guard let idx = tasks.firstIndex(where: { $0.id == id }) else { return }
        tasks[idx].enabled.toggle()
        if tasks[idx].enabled {
            tasks[idx].nextRun = Date().addingTimeInterval(tasks[idx].interval)
        }
        saveTasks()
    }

    private func checkAndRun() {
        let now = Date()
        for i in tasks.indices {
            guard tasks[i].enabled, let nextRun = tasks[i].nextRun, now >= nextRun else { continue }
            let timestamp = FormatUtils.formatDate(now)
            logs.insert("[\(timestamp)] \(L10n.t("scheduler.running")): \(tasks[i].profileName)", at: 0)
            tasks[i].lastRun = now
            tasks[i].nextRun = now.addingTimeInterval(tasks[i].interval)
            // Note: actual sync execution would need SyncViewModel reference
            // For now just log it
        }
        saveTasks()
        saveLogs()
    }

    func saveLogs() {
        let toSave = Array(logs.prefix(AppConstants.maxSchedulerLogs))
        if let data = try? JSONSerialization.data(withJSONObject: toSave) {
            try? data.write(to: logsURL)
        }
    }

    func loadLogs() {
        guard let data = try? Data(contentsOf: logsURL),
              let loaded = try? JSONSerialization.jsonObject(with: data) as? [String]
        else { return }
        logs = loaded
    }

    func saveTasks() {
        if let data = try? JSONEncoder().encode(tasks) {
            try? data.write(to: configURL)
        }
    }

    func loadTasks() {
        guard let data = try? Data(contentsOf: configURL),
              let loaded = try? JSONDecoder().decode([ScheduledTask].self, from: data)
        else { return }
        tasks = loaded
    }
}
