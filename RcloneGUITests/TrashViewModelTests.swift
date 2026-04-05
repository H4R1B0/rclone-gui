import Testing
import Foundation
@testable import RcloneGUI
import RcloneKit

@Suite("TrashViewModel Tests")
struct TrashViewModelTests {
    private func makeTempURL() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("trash_test_\(UUID().uuidString).json")
    }

    @Test("Record deletion stores item with correct size")
    func recordDeletion() {
        let mock = MockRcloneClient()
        let vm = TrashViewModel(client: mock, configURL: makeTempURL())
        vm.recordDeletion(name: "file.txt", fs: "gdrive:", path: "/docs/file.txt", size: 1024)
        #expect(vm.items.count == 1)
        #expect(vm.items[0].name == "file.txt")
        #expect(vm.items[0].size == 1024)
    }

    @Test("Total size calculation")
    func totalSize() {
        let mock = MockRcloneClient()
        let vm = TrashViewModel(client: mock, configURL: makeTempURL())
        vm.recordDeletion(name: "a", fs: "/", path: "a", size: 100)
        vm.recordDeletion(name: "b", fs: "/", path: "b", size: 200)
        #expect(vm.totalSize == 300)
    }

    @Test("Clear all")
    func clearAll() {
        let mock = MockRcloneClient()
        let vm = TrashViewModel(client: mock, configURL: makeTempURL())
        vm.recordDeletion(name: "x", fs: "/", path: "x", size: 50)
        vm.clearAll()
        #expect(vm.items.isEmpty)
    }

    @Test("Max 500 items")
    func maxItems() {
        let mock = MockRcloneClient()
        let vm = TrashViewModel(client: mock, configURL: makeTempURL())
        for i in 0..<510 {
            vm.recordDeletion(name: "file\(i)", fs: "/", path: "file\(i)", size: 1)
        }
        #expect(vm.items.count == 500)
    }

    @Test("Remove by ID")
    func removeById() {
        let mock = MockRcloneClient()
        let vm = TrashViewModel(client: mock, configURL: makeTempURL())
        vm.recordDeletion(name: "keep", fs: "/", path: "keep", size: 10)
        vm.recordDeletion(name: "remove", fs: "/", path: "remove", size: 20)
        let removeId = vm.items.first { $0.name == "remove" }!.id
        vm.remove(id: removeId)
        #expect(vm.items.count == 1)
        #expect(vm.items[0].name == "keep")
    }

    @Test("TrashedFile stores directory flag")
    func directoryFlag() {
        let item = TrashedFile(name: "folder", originalFs: "/", originalPath: "/folder",
                               size: 1024000, isDir: true, trashFs: "/", trashPath: "/.Trash/folder")
        #expect(item.isDir == true)
        #expect(item.size == 1024000)
    }

    @Test("TrashedFile stores non-zero size for directories")
    func directorySizePreserved() {
        let mock = MockRcloneClient()
        let vm = TrashViewModel(client: mock, configURL: makeTempURL())
        // Simulate adding a directory with calculated size (9.54GB)
        let bigDirSize: Int64 = 9_540_000_000
        let item = TrashedFile(name: "BigFolder", originalFs: "/", originalPath: "/BigFolder",
                               size: bigDirSize, isDir: true, trashFs: "/", trashPath: "/.Trash/BigFolder")
        vm.items.insert(item, at: 0)
        #expect(vm.items[0].size == bigDirSize)
        #expect(vm.totalSize == bigDirSize)
    }

    @Test("Items inserted at front")
    func insertionOrder() {
        let mock = MockRcloneClient()
        let vm = TrashViewModel(client: mock, configURL: makeTempURL())
        vm.recordDeletion(name: "first", fs: "/", path: "first", size: 10)
        vm.recordDeletion(name: "second", fs: "/", path: "second", size: 20)
        #expect(vm.items[0].name == "second")
        #expect(vm.items[1].name == "first")
    }
}
