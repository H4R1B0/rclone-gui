import Foundation
import RcloneKit

public struct FileOperations: Sendable {
    private let client: RcloneClientProtocol

    public init(client: RcloneClientProtocol) {
        self.client = client
    }

    public func list(fs: String, path: String) async throws -> [FileItem] {
        try await RcloneAPI.listFiles(using: client, fs: fs, remote: path)
    }

    public func mkdir(fs: String, path: String) async throws {
        try await RcloneAPI.mkdir(using: client, fs: fs, remote: path)
    }

    public func delete(fs: String, remote: String, isDir: Bool) async throws {
        if isDir {
            try await RcloneAPI.purge(using: client, fs: fs, remote: remote)
        } else {
            try await RcloneAPI.deleteFile(using: client, fs: fs, remote: remote)
        }
    }

    public func rename(fs: String, path: String, from: String, to: String) async throws {
        let srcRemote = path.isEmpty ? from : "\(path)/\(from)"
        let dstRemote = path.isEmpty ? to : "\(path)/\(to)"
        try await RcloneAPI.moveFile(
            using: client,
            srcFs: fs, srcRemote: srcRemote,
            dstFs: fs, dstRemote: dstRemote
        )
    }

    public func copy(srcFs: String, srcRemote: String, dstFs: String, dstRemote: String) async throws {
        try await RcloneAPI.copyFile(
            using: client,
            srcFs: srcFs, srcRemote: srcRemote,
            dstFs: dstFs, dstRemote: dstRemote
        )
    }

    public func move(srcFs: String, srcRemote: String, dstFs: String, dstRemote: String) async throws {
        try await RcloneAPI.moveFile(
            using: client,
            srcFs: srcFs, srcRemote: srcRemote,
            dstFs: dstFs, dstRemote: dstRemote
        )
    }
}
