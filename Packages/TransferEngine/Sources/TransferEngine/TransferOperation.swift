import Foundation
import RcloneKit

public struct TransferOperation: Identifiable, Sendable {
    public let id: UUID
    public let kind: TransferKind
    public let source: Location
    public let destination: Location
    public let fileName: String
    public let createdAt: Date

    public var status: TransferStatus
    public var progress: Double
    public var bytesTransferred: Int64
    public var totalBytes: Int64
    public var speed: String
    public var eta: String

    public init(kind: TransferKind, source: Location, destination: Location) {
        self.id = UUID()
        self.kind = kind
        self.source = source
        self.destination = destination
        self.fileName = (source.path as NSString).lastPathComponent
        self.createdAt = Date()
        self.status = .pending
        self.progress = 0
        self.bytesTransferred = 0
        self.totalBytes = 0
        self.speed = ""
        self.eta = ""
    }
}
