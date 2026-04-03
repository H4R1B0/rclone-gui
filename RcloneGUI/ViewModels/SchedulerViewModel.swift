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

    private var timer: Timer?
    private let configURL: URL
    private let logsURL: URL

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupport.appendingPathComponent("RcloneGUI")
        try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
        configURL = appDir.appendingPathComponent("scheduler.json")
        logsURL = appDir.appendingPathComponent("scheduler-logs.json")
        loadTasks()
        loadLogs()
    }

    func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.checkAndRun()
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
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
        let maxLogs = 500
        let toSave = Array(logs.prefix(maxLogs))
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
