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
}
