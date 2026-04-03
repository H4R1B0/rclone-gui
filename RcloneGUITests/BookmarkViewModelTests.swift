import Testing
@testable import RcloneGUI

@Suite("BookmarkViewModel Tests")
struct BookmarkViewModelTests {
    @Test("Add bookmark")
    func addBookmark() {
        let vm = BookmarkViewModel()
        vm.bookmarks = []  // start clean
        vm.add(name: "Test", fs: "gdrive:", path: "/Documents")
        #expect(vm.bookmarks.count == 1)
        #expect(vm.bookmarks[0].name == "Test")
        #expect(vm.bookmarks[0].fs == "gdrive:")
    }

    @Test("Remove bookmark")
    func removeBookmark() {
        let vm = BookmarkViewModel()
        vm.bookmarks = []
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
}
