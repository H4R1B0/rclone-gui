import Testing
@testable import RcloneGUI

@Suite("PathUtils Tests")
struct PathUtilsTests {
    @Test("join — simple")
    func joinSimple() { #expect(PathUtils.join("a", "b") == "a/b") }

    @Test("join — empty parts filtered")
    func joinEmpty() { #expect(PathUtils.join("a", "", "b") == "a/b") }

    @Test("join — collapse slashes")
    func joinSlashes() { #expect(!PathUtils.join("a/", "/b").contains("//")) }

    @Test("parent — normal path")
    func parentNormal() { #expect(PathUtils.parent("a/b/c") == "a/b") }

    @Test("parent — single segment")
    func parentSingle() { #expect(PathUtils.parent("a") == "") }

    @Test("parent — empty")
    func parentEmpty() { #expect(PathUtils.parent("") == "") }

    @Test("fileName")
    func fileName() { #expect(PathUtils.fileName("a/b/c.txt") == "c.txt") }

    @Test("segments")
    func segments() { #expect(PathUtils.segments("a/b/c") == ["a", "b", "c"]) }

    @Test("segments — empty")
    func segmentsEmpty() { #expect(PathUtils.segments("").isEmpty) }

    @Test("pathUpTo — index 0")
    func pathUpToZero() {
        let segs = ["a", "b", "c"]
        #expect(PathUtils.pathUpTo(segments: segs, index: 0) == "a")
    }

    @Test("pathUpTo — index 1")
    func pathUpToOne() {
        let segs = ["a", "b", "c"]
        #expect(PathUtils.pathUpTo(segments: segs, index: 1) == "a/b")
    }
}
