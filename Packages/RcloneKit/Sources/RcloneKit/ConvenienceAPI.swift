import Foundation

public enum RcloneAPI {
    public static func listRemotes(using client: RcloneClientProtocol) async throws -> [String] {
        let result = try await client.call("config/listremotes", params: [:])
        return result["remotes"] as? [String] ?? []
    }

    public static func listFiles(
        using client: RcloneClientProtocol,
        fs: String,
        remote: String
    ) async throws -> [FileItem] {
        let result = try await client.call("operations/list", params: [
            "fs": fs,
            "remote": remote,
            "opt": ["recurse": false]
        ])
        guard let list = result["list"] else {
            return []
        }
        let data = try JSONSerialization.data(withJSONObject: list)
        return try JSONDecoder.rclone.decode([FileItem].self, from: data)
    }

    public static func mkdir(
        using client: RcloneClientProtocol,
        fs: String,
        remote: String
    ) async throws {
        _ = try await client.call("operations/mkdir", params: ["fs": fs, "remote": remote])
    }

    public static func deleteFile(
        using client: RcloneClientProtocol,
        fs: String,
        remote: String
    ) async throws {
        _ = try await client.call("operations/deletefile", params: ["fs": fs, "remote": remote])
    }

    public static func purge(
        using client: RcloneClientProtocol,
        fs: String,
        remote: String
    ) async throws {
        _ = try await client.call("operations/purge", params: ["fs": fs, "remote": remote])
    }

    public static func moveFile(
        using client: RcloneClientProtocol,
        srcFs: String,
        srcRemote: String,
        dstFs: String,
        dstRemote: String
    ) async throws {
        _ = try await client.call("operations/movefile", params: [
            "srcFs": srcFs, "srcRemote": srcRemote,
            "dstFs": dstFs, "dstRemote": dstRemote
        ])
    }

    public static func copyFile(
        using client: RcloneClientProtocol,
        srcFs: String,
        srcRemote: String,
        dstFs: String,
        dstRemote: String
    ) async throws {
        _ = try await client.call("operations/copyfile", params: [
            "srcFs": srcFs, "srcRemote": srcRemote,
            "dstFs": dstFs, "dstRemote": dstRemote
        ])
    }

    public static func getRemoteType(
        using client: RcloneClientProtocol,
        name: String
    ) async throws -> String {
        let result = try await client.call("config/get", params: ["name": name])
        return result["type"] as? String ?? "unknown"
    }

    public static func createRemote(
        using client: RcloneClientProtocol,
        name: String,
        type: String,
        parameters: [String: String]
    ) async throws {
        _ = try await client.call("config/create", params: [
            "name": name, "type": type, "parameters": parameters
        ])
    }

    public static func deleteRemote(
        using client: RcloneClientProtocol,
        name: String
    ) async throws {
        _ = try await client.call("config/delete", params: ["name": name])
    }

    // MARK: - Providers

    public static func getProviders(using client: RcloneClientProtocol) async throws -> [RcloneProvider] {
        let result = try await client.call("config/providers", params: [:])
        guard let providers = result["providers"] as? [[String: Any]] else { return [] }
        return providers.map { RcloneProvider(from: $0) }
    }

    public static func getRemoteConfig(using client: RcloneClientProtocol, name: String) async throws -> [String: Any] {
        return try await client.call("config/get", params: ["name": name])
    }

    // MARK: - Async File Operations (return jobid)

    public static func copyFileAsync(
        using client: RcloneClientProtocol,
        srcFs: String, srcRemote: String,
        dstFs: String, dstRemote: String
    ) async throws -> Int {
        let result = try await client.call("operations/copyfile", params: [
            "srcFs": srcFs, "srcRemote": srcRemote,
            "dstFs": dstFs, "dstRemote": dstRemote,
            "_async": true
        ])
        return result["jobid"] as? Int ?? 0
    }

    public static func moveFileAsync(
        using client: RcloneClientProtocol,
        srcFs: String, srcRemote: String,
        dstFs: String, dstRemote: String
    ) async throws -> Int {
        let result = try await client.call("operations/movefile", params: [
            "srcFs": srcFs, "srcRemote": srcRemote,
            "dstFs": dstFs, "dstRemote": dstRemote,
            "_async": true
        ])
        return result["jobid"] as? Int ?? 0
    }

    // MARK: - Directory Operations (async)

    public static func copyDir(
        using client: RcloneClientProtocol,
        srcFs: String, srcRemote: String,
        dstFs: String, dstRemote: String
    ) async throws -> Int {
        let result = try await client.call("sync/copy", params: [
            "srcFs": "\(srcFs)\(srcRemote)",
            "dstFs": "\(dstFs)\(dstRemote)",
            "_async": true
        ])
        return result["jobid"] as? Int ?? 0
    }

    public static func moveDir(
        using client: RcloneClientProtocol,
        srcFs: String, srcRemote: String,
        dstFs: String, dstRemote: String
    ) async throws -> Int {
        let result = try await client.call("sync/move", params: [
            "srcFs": "\(srcFs)\(srcRemote)",
            "dstFs": "\(dstFs)\(dstRemote)",
            "_async": true
        ])
        return result["jobid"] as? Int ?? 0
    }

    // MARK: - Transfer Monitoring

    public static func getStats(using client: RcloneClientProtocol) async throws -> RcloneStats {
        let result = try await client.call("core/stats", params: [:])
        return RcloneStats(from: result)
    }

    public static func getTransferred(using client: RcloneClientProtocol) async throws -> [RcloneCompletedTransfer] {
        let result = try await client.call("core/transferred", params: [:])
        guard let transferred = result["transferred"] as? [[String: Any]] else { return [] }
        return transferred.map { RcloneCompletedTransfer(from: $0) }
    }

    public static func resetStats(using client: RcloneClientProtocol) async throws {
        _ = try await client.call("core/stats-reset", params: [:])
    }

    // MARK: - Job Management

    public static func getJobList(using client: RcloneClientProtocol) async throws -> [Int] {
        let result = try await client.call("job/list", params: [:])
        guard let jobids = result["jobids"] as? [Int] else { return [] }
        return jobids
    }

    public static func stopJob(using client: RcloneClientProtocol, jobid: Int) async throws {
        _ = try await client.call("job/stop", params: ["jobid": jobid])
    }

    public static func getJobStatus(using client: RcloneClientProtocol, jobid: Int) async throws -> RcloneJobStatus {
        let result = try await client.call("job/status", params: ["jobid": jobid])
        return RcloneJobStatus(from: result)
    }

    // MARK: - Settings

    public static func setBwLimit(using client: RcloneClientProtocol, rate: String) async throws {
        _ = try await client.call("core/bwlimit", params: ["rate": rate])
    }

    // MARK: - Sync Operations

    /// One-way sync: make destination identical to source (deletes extra files in dst)
    public static func syncSync(
        using client: RcloneClientProtocol,
        srcFs: String, srcRemote: String,
        dstFs: String, dstRemote: String,
        async: Bool = true
    ) async throws -> Int {
        let result = try await client.call("sync/sync", params: [
            "srcFs": "\(srcFs)\(srcRemote)",
            "dstFs": "\(dstFs)\(dstRemote)",
            "_async": async
        ])
        return result["jobid"] as? Int ?? 0
    }

    /// Bidirectional sync
    public static func bisync(
        using client: RcloneClientProtocol,
        path1: String, path2: String,
        async: Bool = true
    ) async throws -> Int {
        let result = try await client.call("sync/bisync", params: [
            "path1": path1,
            "path2": path2,
            "_async": async
        ])
        return result["jobid"] as? Int ?? 0
    }

    // MARK: - Mount

    public static func mount(
        using client: RcloneClientProtocol,
        fs: String, mountPoint: String,
        options: [String: Any] = [:]
    ) async throws {
        var params: [String: Any] = ["fs": fs, "mountPoint": mountPoint]
        for (k, v) in options { params[k] = v }
        _ = try await client.call("mount/mount", params: params)
    }

    public static func unmount(
        using client: RcloneClientProtocol,
        mountPoint: String
    ) async throws {
        _ = try await client.call("mount/unmount", params: ["mountPoint": mountPoint])
    }

    public static func listMounts(using client: RcloneClientProtocol) async throws -> [[String: Any]] {
        let result = try await client.call("mount/listmounts", params: [:])
        return result["mountPoints"] as? [[String: Any]] ?? []
    }

    // MARK: - Hash

    public static func hashFile(
        using client: RcloneClientProtocol,
        fs: String, remote: String,
        hashTypes: [String] = ["md5", "sha1"]
    ) async throws -> [String: String] {
        var hashes: [String: String] = [:]
        for hashType in hashTypes {
            do {
                let result = try await client.call("operations/hashfile", params: [
                    "fs": fs, "remote": remote, "hashType": hashType
                ])
                if let hash = result["hash"] as? String {
                    hashes[hashType] = hash
                }
            } catch {
                // Hash may not be supported for this backend, skip
            }
        }
        return hashes
    }
}
