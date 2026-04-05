import Foundation
import RcloneKit

enum SyncMode: String, CaseIterable {
    case mirror       // sync/sync — 완전 복제 (타겟의 불필요 파일 삭제)
    case mirrorUpdate // sync/copy — 변경된 파일만 복사
    case bisync       // sync/bisync — 양방향 동기화

    var label: String {
        switch self {
        case .mirror: return L10n.t("sync.mirror")
        case .mirrorUpdate: return L10n.t("sync.mirrorUpdate")
        case .bisync: return L10n.t("sync.bisync")
        }
    }

    var description: String {
        switch self {
        case .mirror: return L10n.t("sync.mirror.desc")
        case .mirrorUpdate: return L10n.t("sync.mirrorUpdate.desc")
        case .bisync: return L10n.t("sync.bisync.desc")
        }
    }
}

struct SyncProfile: Identifiable, Codable {
    let id: UUID
    var name: String
    var mode: String  // SyncMode.rawValue
    var sourceFs: String
    var sourcePath: String
    var destFs: String
    var destPath: String
    var filterRules: [String]  // e.g., ["*.tmp", "*.log"]
    var createdAt: Date

    init(name: String, mode: SyncMode, sourceFs: String, sourcePath: String, destFs: String, destPath: String, filterRules: [String] = []) {
        self.id = UUID()
        self.name = name
        self.mode = mode.rawValue
        self.sourceFs = sourceFs
        self.sourcePath = sourcePath
        self.destFs = destFs
        self.destPath = destPath
        self.filterRules = filterRules
        self.createdAt = Date()
    }

    var syncMode: SyncMode { SyncMode(rawValue: mode) ?? .mirror }
}

@Observable
final class SyncViewModel {
    var profiles: [SyncProfile] = []
    var isRunning: Bool = false
    var currentJobId: Int?
    var error: String?
    var logs: [String] = []

    private let client: RcloneClientProtocol
    private let profilesURL: URL

    init(client: RcloneClientProtocol, profilesURL: URL? = nil) {
        self.client = client
        self.profilesURL = profilesURL ?? AppConstants.appSupportDir.appendingPathComponent(AppConstants.syncProfilesFile)
        loadProfiles()
    }

    // MARK: - Sync Execution

    @MainActor
    func runSync(profile: SyncProfile) async {
        isRunning = true
        error = nil
        let timestamp = FormatUtils.formatDate(Date())
        logs.insert("[\(timestamp)] \(L10n.t("sync.started")): \(profile.name)", at: 0)

        do {
            let jobId: Int
            switch profile.syncMode {
            case .mirror:
                jobId = try await RcloneAPI.syncSync(
                    using: client,
                    srcFs: profile.sourceFs, srcRemote: profile.sourcePath,
                    dstFs: profile.destFs, dstRemote: profile.destPath,
                    filterRules: profile.filterRules
                )
            case .mirrorUpdate:
                jobId = try await RcloneAPI.copyDir(
                    using: client,
                    srcFs: profile.sourceFs, srcRemote: profile.sourcePath,
                    dstFs: profile.destFs, dstRemote: profile.destPath,
                    filterRules: profile.filterRules
                )
            case .bisync:
                jobId = try await RcloneAPI.bisync(
                    using: client,
                    path1: "\(profile.sourceFs)\(profile.sourcePath)",
                    path2: "\(profile.destFs)\(profile.destPath)",
                    filterRules: profile.filterRules
                )
            }
            currentJobId = jobId
            logs.insert("[\(timestamp)] Job ID: \(jobId)", at: 0)
        } catch {
            self.error = error.localizedDescription
            logs.insert("[\(timestamp)] \(L10n.t("sync.failed")): \(error.localizedDescription)", at: 0)
        }

        isRunning = false
    }

    @MainActor
    func stopSync() async {
        guard let jobId = currentJobId else { return }
        try? await RcloneAPI.stopJob(using: client, jobid: jobId)
        currentJobId = nil
        isRunning = false
        logs.insert("[\(FormatUtils.formatDate(Date()))] \(L10n.t("sync.stopped"))", at: 0)
    }

    // MARK: - Profile Management

    func addProfile(_ profile: SyncProfile) {
        profiles.append(profile)
        saveProfiles()
    }

    func deleteProfile(id: UUID) {
        profiles.removeAll { $0.id == id }
        saveProfiles()
    }

    func updateProfile(_ profile: SyncProfile) {
        if let index = profiles.firstIndex(where: { $0.id == profile.id }) {
            profiles[index] = profile
            saveProfiles()
        }
    }

    func saveProfiles() {
        if let data = try? JSONEncoder().encode(profiles) {
            try? data.write(to: profilesURL)
        }
    }

    func loadProfiles() {
        guard let data = try? Data(contentsOf: profilesURL),
              let loaded = try? JSONDecoder().decode([SyncProfile].self, from: data)
        else { return }
        profiles = loaded
    }
}
