import Testing
@testable import RcloneGUI

@Suite("ErrorClassifier Tests")
struct ErrorClassifierTests {
    @Test("Auth error classified correctly")
    func authError() {
        let c = ErrorClassifier.classify("token expired: 401 Unauthorized")
        #expect(c.severity == .error)
        #expect(c.actionLabel != nil)
    }

    @Test("Quota error classified correctly")
    func quotaError() {
        let c = ErrorClassifier.classify("quota exceeded: insufficient storage space")
        #expect(c.severity == .warning)
    }

    @Test("Network error classified correctly")
    func networkError() {
        let c = ErrorClassifier.classify("connection timeout: network unreachable")
        #expect(c.severity == .warning)
        #expect(c.actionLabel != nil)  // retry
    }

    @Test("Not found error classified correctly")
    func notFoundError() {
        let c = ErrorClassifier.classify("404 not found: no such file")
        #expect(c.severity == .warning)
    }

    @Test("Rate limit error classified correctly")
    func rateLimitError() {
        let c = ErrorClassifier.classify("429 too many requests: rate limit")
        #expect(c.severity == .info)
    }

    @Test("Conflict error classified correctly")
    func conflictError() {
        let c = ErrorClassifier.classify("file already exists: conflict")
        #expect(c.severity == .warning)
    }

    @Test("Unknown error gets generic classification")
    func unknownError() {
        let c = ErrorClassifier.classify("some random error xyz")
        #expect(c.severity == .error)
        #expect(c.originalMessage == "some random error xyz")
    }
}
