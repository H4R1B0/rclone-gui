import Foundation

struct TransferCheckpoint: Codable, Identifiable {
    let id: UUID
    let fileName: String
    let srcFs: String
    let srcRemote: String
    let dstFs: String
    let dstRemote: String
    let isDir: Bool
    let totalSize: Int64
    var bytesTransferred: Int64
    let startedAt: Date
    var lastAttempt: Date
    var attempts: Int
    var lastError: String?

    init(fileName: String, srcFs: String, srcRemote: String, dstFs: String, dstRemote: String, isDir: Bool, totalSize: Int64) {
        self.id = UUID()
        self.fileName = fileName
        self.srcFs = srcFs
        self.srcRemote = srcRemote
        self.dstFs = dstFs
        self.dstRemote = dstRemote
        self.isDir = isDir
        self.totalSize = totalSize
        self.bytesTransferred = 0
        self.startedAt = Date()
        self.lastAttempt = Date()
        self.attempts = 0
        self.lastError = nil
    }
}
