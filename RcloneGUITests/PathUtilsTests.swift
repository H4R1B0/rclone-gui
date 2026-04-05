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

    @Test("pathUpTo — absolute path preserves leading slash")
    func pathUpToAbsolute() {
        let segs = ["Volumes", "SSD", "Project"]
        #expect(PathUtils.pathUpTo(segments: segs, index: 0, absolute: true) == "/Volumes")
        #expect(PathUtils.pathUpTo(segments: segs, index: 1, absolute: true) == "/Volumes/SSD")
        #expect(PathUtils.pathUpTo(segments: segs, index: 2, absolute: true) == "/Volumes/SSD/Project")
    }

    @Test("pathUpTo — non-absolute (cloud) path has no leading slash")
    func pathUpToRelative() {
        let segs = ["Documents", "Photos"]
        #expect(PathUtils.pathUpTo(segments: segs, index: 0, absolute: false) == "Documents")
        #expect(PathUtils.pathUpTo(segments: segs, index: 1, absolute: false) == "Documents/Photos")
    }

    @Test("segments — absolute path strips leading slash")
    func segmentsAbsolute() {
        #expect(PathUtils.segments("/Volumes/SSD") == ["Volumes", "SSD"])
    }

    @Test("fileName — absolute path")
    func fileNameAbsolute() {
        #expect(PathUtils.fileName("/Volumes/SSD/Project") == "Project")
    }

    @Test("parent — absolute path")
    func parentAbsolute() {
        #expect(PathUtils.parent("/Volumes/SSD/Project") == "Volumes/SSD")
    }
}
