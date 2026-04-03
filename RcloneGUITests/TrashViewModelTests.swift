import Testing
@testable import RcloneGUI

@Suite("TrashViewModel Tests")
struct TrashViewModelTests {
    @Test("Record deletion")
    func recordDeletion() {
        let vm = TrashViewModel()
        vm.items = []  // start clean
        vm.recordDeletion(name: "file.txt", fs: "gdrive:", path: "/docs/file.txt", size: 1024)
        #expect(vm.items.count == 1)
        #expect(vm.items[0].name == "file.txt")
        #expect(vm.items[0].size == 1024)
    }

    @Test("Total size calculation")
    func totalSize() {
        let vm = TrashViewModel()
        vm.items = []
        vm.recordDeletion(name: "a", fs: "/", path: "a", size: 100)
        vm.recordDeletion(name: "b", fs: "/", path: "b", size: 200)
        #expect(vm.totalSize == 300)
    }

    @Test("Clear all")
    func clearAll() {
        let vm = TrashViewModel()
        vm.items = []
        vm.recordDeletion(name: "x", fs: "/", path: "x", size: 50)
        vm.clearAll()
        #expect(vm.items.isEmpty)
    }

    @Test("Max 500 items")
    func maxItems() {
        let vm = TrashViewModel()
        vm.items = []
        for i in 0..<510 {
            vm.recordDeletion(name: "file\(i)", fs: "/", path: "file\(i)", size: 1)
        }
        #expect(vm.items.count == 500)
    }

    @Test("Remove by ID")
    func removeById() {
        let vm = TrashViewModel()
        vm.items = []
        vm.recordDeletion(name: "keep", fs: "/", path: "keep", size: 10)
        vm.recordDeletion(name: "remove", fs: "/", path: "remove", size: 20)
        let removeId = vm.items.first { $0.name == "remove" }!.id
        vm.remove(id: removeId)
        #expect(vm.items.count == 1)
        #expect(vm.items[0].name == "keep")
    }
}
