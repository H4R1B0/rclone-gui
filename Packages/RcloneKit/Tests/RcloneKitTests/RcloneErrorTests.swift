import Testing
@testable import RcloneKit

@Suite("RcloneError Tests")
struct RcloneErrorTests {
    @Test("rpcFailed contains method, status, and message")
    func rpcFailedContainsDetails() {
        let error = RcloneError.rpcFailed(method: "operations/list", status: 404, message: "not found")
        let description = error.errorDescription ?? ""
        #expect(description.contains("operations/list"))
        #expect(description.contains("not found"))
    }

    @Test("notInitialized has error message")
    func notInitializedHasMessage() {
        let error = RcloneError.notInitialized
        #expect(error.errorDescription != nil)
        #expect(error.errorDescription!.contains("not initialized"))
    }

    @Test("encodingFailed has error message")
    func encodingFailedHasMessage() {
        let error = RcloneError.encodingFailed
        #expect(error.errorDescription != nil)
    }

    @Test("decodingFailed includes detail")
    func decodingFailedIncludesDetail() {
        let error = RcloneError.decodingFailed("bad json")
        #expect(error.errorDescription!.contains("bad json"))
    }

    @Test("RcloneError is Equatable")
    func equatable() {
        #expect(RcloneError.notInitialized == RcloneError.notInitialized)
        #expect(RcloneError.encodingFailed == RcloneError.encodingFailed)
        #expect(RcloneError.notInitialized != RcloneError.encodingFailed)
    }
}
