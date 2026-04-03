import Testing
import Foundation
@testable import TransferEngine
import RcloneKit

@Suite("TransferOperation Tests")
struct TransferOperationTests {
    @Test("Initial status is pending")
    func initialStatusIsPending() {
        let op = TransferOperation(
            kind: .copy,
            source: Location(fs: "gdrive:", path: "/file.txt"),
            destination: Location(fs: "dropbox:", path: "/file.txt")
        )
        #expect(op.status == .pending)
        #expect(op.progress == 0)
        #expect(op.fileName == "file.txt")
    }

    @Test("Status transition: pending → transferring → completed")
    func statusTransitions() {
        var op = TransferOperation(
            kind: .copy,
            source: Location(fs: "gdrive:", path: "/file.txt"),
            destination: Location(fs: "dropbox:", path: "/file.txt")
        )
        op.status = .transferring
        op.progress = 0.5
        #expect(op.status == .transferring)

        op.status = .completed
        op.progress = 1.0
        #expect(op.status == .completed)
        #expect(op.status.isTerminal)
    }

    @Test("Failed status contains message")
    func failureTransition() {
        var op = TransferOperation(
            kind: .move,
            source: Location(fs: "gdrive:", path: "/big.zip"),
            destination: Location(fs: "/", path: "/Downloads/big.zip")
        )
        op.status = .failed(message: "Network error")

        if case .failed(let msg) = op.status {
            #expect(msg == "Network error")
        } else {
            Issue.record("Expected failed status")
        }
        #expect(op.status.isTerminal)
    }

    @Test("Pending and transferring are not terminal")
    func nonTerminalStates() {
        #expect(!TransferStatus.pending.isTerminal)
        #expect(!TransferStatus.transferring.isTerminal)
        #expect(!TransferStatus.paused.isTerminal)
    }
}
