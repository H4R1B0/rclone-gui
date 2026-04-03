import Testing
@testable import RcloneGUI

@Suite("ClipboardState Tests")
struct ClipboardStateTests {
    @Test("Initial state — no data")
    func initialState() {
        let clipboard = ClipboardState()
        #expect(!clipboard.hasData)
        #expect(clipboard.action == nil)
    }

    @Test("Copy sets state")
    func copyAction() {
        let clipboard = ClipboardState()
        clipboard.copy(fs: "gdrive:", path: "/docs", selectedFiles: [("file.txt", false)])
        #expect(clipboard.hasData)
        #expect(clipboard.action == .copy)
        #expect(clipboard.sourceFs == "gdrive:")
        #expect(clipboard.sourcePath == "/docs")
        #expect(clipboard.files.count == 1)
    }

    @Test("Cut sets state")
    func cutAction() {
        let clipboard = ClipboardState()
        clipboard.cut(fs: "/", path: "/home", selectedFiles: [("a.txt", false), ("b/", true)])
        #expect(clipboard.hasData)
        #expect(clipboard.action == .cut)
        #expect(clipboard.files.count == 2)
    }

    @Test("Clear resets state")
    func clearAction() {
        let clipboard = ClipboardState()
        clipboard.copy(fs: "/", path: "", selectedFiles: [("x", false)])
        #expect(clipboard.hasData)
        clipboard.clear()
        #expect(!clipboard.hasData)
        #expect(clipboard.action == nil)
        #expect(clipboard.files.isEmpty)
    }

    @Test("Copy overwrites previous cut")
    func overwriteAction() {
        let clipboard = ClipboardState()
        clipboard.cut(fs: "/", path: "", selectedFiles: [("old", false)])
        clipboard.copy(fs: "s3:", path: "/bucket", selectedFiles: [("new", false)])
        #expect(clipboard.action == .copy)
        #expect(clipboard.sourceFs == "s3:")
        #expect(clipboard.files[0].name == "new")
    }
}
