import Testing
import Foundation
@testable import RcloneGUI

@Suite("BookmarkViewModel Tests")
struct BookmarkViewModelTests {
    private func makeTempURL() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("bm_test_\(UUID().uuidString).json")
    }

    @Test("Add bookmark")
    func addBookmark() {
        let vm = BookmarkViewModel(configURL: makeTempURL())
        vm.add(name: "Test", fs: "gdrive:", path: "/Documents")
        #expect(vm.bookmarks.count == 1)
        #expect(vm.bookmarks[0].name == "Test")
        #expect(vm.bookmarks[0].fs == "gdrive:")
    }

    @Test("Remove bookmark")
    func removeBookmark() {
        let vm = BookmarkViewModel(configURL: makeTempURL())
        vm.add(name: "A", fs: "/", path: "/home")
        let id = vm.bookmarks[0].id
        vm.remove(id: id)
        #expect(vm.bookmarks.isEmpty)
    }

    @Test("Bookmark displayPath — local")
    func displayPathLocal() {
        let b = Bookmark(name: "Home", fs: "/", path: "Users/test")
        #expect(b.displayPath == "/Users/test")
    }

    @Test("Bookmark displayPath — cloud")
    func displayPathCloud() {
        let b = Bookmark(name: "Drive", fs: "gdrive:", path: "Documents")
        #expect(b.displayPath == "gdrive:Documents")
    }

    @Test("isBookmarked returns true for existing bookmark")
    func isBookmarkedTrue() {
        let vm = BookmarkViewModel(configURL: makeTempURL())
        vm.add(name: "Docs", fs: "gdrive:", path: "/Documents")
        #expect(vm.isBookmarked(fs: "gdrive:", path: "/Documents"))
    }

    @Test("isBookmarked returns false for non-existing bookmark")
    func isBookmarkedFalse() {
        let vm = BookmarkViewModel(configURL: makeTempURL())
        #expect(!vm.isBookmarked(fs: "gdrive:", path: "/Documents"))
    }

    @Test("toggle adds bookmark when not present")
    func toggleAdds() {
        let vm = BookmarkViewModel(configURL: makeTempURL())
        vm.toggle(fs: "gdrive:", path: "/Photos")
        #expect(vm.bookmarks.count == 1)
        #expect(vm.bookmarks[0].name == "Photos")
        #expect(vm.isBookmarked(fs: "gdrive:", path: "/Photos"))
    }

    @Test("toggle removes bookmark when already present")
    func toggleRemoves() {
        let vm = BookmarkViewModel(configURL: makeTempURL())
        vm.add(name: "Photos", fs: "gdrive:", path: "/Photos")
        #expect(vm.bookmarks.count == 1)
        vm.toggle(fs: "gdrive:", path: "/Photos")
        #expect(vm.bookmarks.isEmpty)
        #expect(!vm.isBookmarked(fs: "gdrive:", path: "/Photos"))
    }

    @Test("toggle uses folder name as bookmark name")
    func toggleUsesFileName() {
        let vm = BookmarkViewModel(configURL: makeTempURL())
        vm.toggle(fs: "s3:", path: "/bucket/data")
        #expect(vm.bookmarks[0].name == "data")
    }

    @Test("toggle uses remote as name when path is empty")
    func toggleUsesRemoteForEmptyPath() {
        let vm = BookmarkViewModel(configURL: makeTempURL())
        vm.toggle(fs: "gdrive:", path: "")
        #expect(vm.bookmarks[0].name == "gdrive:")
    }

    @Test("Multiple bookmarks independent")
    func multipleBookmarks() {
        let vm = BookmarkViewModel(configURL: makeTempURL())
        vm.add(name: "A", fs: "/", path: "/home")
        vm.add(name: "B", fs: "gdrive:", path: "/docs")
        vm.add(name: "C", fs: "s3:", path: "/bucket")
        #expect(vm.bookmarks.count == 3)
        #expect(vm.isBookmarked(fs: "/", path: "/home"))
        #expect(vm.isBookmarked(fs: "gdrive:", path: "/docs"))
        #expect(vm.isBookmarked(fs: "s3:", path: "/bucket"))
    }

    @Test("Remove non-existent ID is safe")
    func removeNonExistent() {
        let vm = BookmarkViewModel(configURL: makeTempURL())
        vm.add(name: "A", fs: "/", path: "/home")
        vm.remove(id: UUID())
        #expect(vm.bookmarks.count == 1)
    }

    @Test("Save and load round-trip")
    func saveLoadRoundTrip() {
        let sharedURL = makeTempURL()
        let vm = BookmarkViewModel(configURL: sharedURL)
        vm.add(name: "Saved", fs: "gdrive:", path: "/saved")
        let vm2 = BookmarkViewModel(configURL: sharedURL)
        #expect(vm2.bookmarks.count == 1)
        #expect(vm2.bookmarks[0].name == "Saved")
        #expect(vm2.bookmarks[0].fs == "gdrive:")
        #expect(vm2.bookmarks[0].path == "/saved")
    }

    @Test("Bookmark createdAt is set")
    func createdAtSet() {
        let before = Date()
        let b = Bookmark(name: "Test", fs: "/", path: "/test")
        let after = Date()
        #expect(b.createdAt >= before)
        #expect(b.createdAt <= after)
    }

    @Test("Bookmark unique IDs")
    func uniqueIds() {
        let a = Bookmark(name: "A", fs: "/", path: "/a")
        let b = Bookmark(name: "B", fs: "/", path: "/b")
        #expect(a.id != b.id)
    }
}
