import Testing
import Foundation
@testable import RcloneGUI

@Suite("URLSchemeHandler Tests")
struct URLSchemeHandlerTests {
    @Test("parseQuery — single param")
    func parseQuerySingle() {
        let params = URLSchemeHandler.parseQuery("remote=gdrive")
        #expect(params["remote"] == "gdrive")
    }

    @Test("parseQuery — multiple params")
    func parseQueryMultiple() {
        let params = URLSchemeHandler.parseQuery("remote=gdrive&path=/Documents")
        #expect(params["remote"] == "gdrive")
        #expect(params["path"] == "/Documents")
    }

    @Test("parseQuery — empty")
    func parseQueryEmpty() {
        let params = URLSchemeHandler.parseQuery(nil)
        #expect(params.isEmpty)
    }

    @Test("parseQuery — url encoded")
    func parseQueryEncoded() {
        let params = URLSchemeHandler.parseQuery("path=%2FMy%20Folder")
        #expect(params["path"] == "/My Folder")
    }

    @Test("parseQuery — value with equals")
    func parseQueryEquals() {
        let params = URLSchemeHandler.parseQuery("token=abc=123")
        #expect(params["token"] == "abc=123")
    }
}
