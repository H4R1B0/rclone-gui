import Foundation
import Testing
@testable import RcloneGUI
import RcloneKit

@Suite("PanelViewModel Tab Tests")
struct PanelViewModelTabTests {
    @Test("init creates default tabs") @MainActor
    func initDefaults() {
        let vm = PanelViewModel(client: MockRcloneClient())
        #expect(vm.left.tabs.count == 1)
        #expect(vm.right.tabs.count == 1)
        #expect(vm.left.activeTab.mode == .local)
        #expect(vm.right.activeTab.mode == .cloud)
        #expect(vm.right.activeTab.remote == "")
        #expect(vm.right.activeTab.label == "")
        #expect(vm.left.viewMode == .list)
        #expect(vm.right.viewMode == .list)
    }

    @Test("resetTab clears to empty cloud state") @MainActor
    func resetTab() {
        let vm = PanelViewModel(client: MockRcloneClient())
        let tab = vm.left.activeTab
        tab.mode = .local
        tab.remote = "/"
        tab.label = "Local"
        tab.selectedFiles = ["test"]
        vm.left.resetTab(tab)
        #expect(tab.mode == .cloud)
        #expect(tab.remote == "")
        #expect(tab.label == "")
        #expect(tab.files.isEmpty)
        #expect(tab.selectedFiles.isEmpty)
    }

    @Test("side returns correct panel") @MainActor
    func sideAccessor() {
        let vm = PanelViewModel(client: MockRcloneClient())
        #expect(vm.side(.left).activeTab.id == vm.left.activeTab.id)
        #expect(vm.side(.right).activeTab.id == vm.right.activeTab.id)
    }

    @Test("otherSide returns opposite") @MainActor
    func otherSide() {
        let vm = PanelViewModel(client: MockRcloneClient())
        #expect(vm.otherSide(.left).activeTab.id == vm.right.activeTab.id)
    }

    @Test("addTab creates and activates") @MainActor
    func addTab() {
        let vm = PanelViewModel(client: MockRcloneClient())
        vm.left.addTab(mode: .cloud, remote: "gdrive:", label: "Drive")
        #expect(vm.left.tabs.count == 2)
        #expect(vm.left.activeTab.mode == .cloud)
        #expect(vm.left.activeTab.remote == "gdrive:")
    }

    @Test("moveTab reorders tabs") @MainActor
    func moveTab() {
        let vm = PanelViewModel(client: MockRcloneClient())
        vm.left.addTab(mode: .cloud, remote: "gdrive:", label: "Drive")
        vm.left.addTab(mode: .cloud, remote: "s3:", label: "S3")
        let ids = vm.left.tabs.map(\.id)
        // Move last tab to first position
        vm.left.moveTab(fromId: ids[2], toId: ids[0])
        #expect(vm.left.tabs[0].label == "S3")
    }

    @Test("closeTab removes and switches") @MainActor
    func closeTab() {
        let vm = PanelViewModel(client: MockRcloneClient())
        vm.left.addTab(mode: .cloud, remote: "s3:", label: "S3")
        let firstId = vm.left.tabs[0].id
        let secondId = vm.left.tabs[1].id
        vm.left.closeTab(id: secondId)
        #expect(vm.left.tabs.count == 1)
        #expect(vm.left.activeTabId == firstId)
    }

    @Test("closeTab prevents closing last") @MainActor
    func closeLastTab() {
        let vm = PanelViewModel(client: MockRcloneClient())
        let onlyId = vm.left.tabs[0].id
        vm.left.closeTab(id: onlyId)
        #expect(vm.left.tabs.count == 1)
    }

    @Test("switchTab changes active") @MainActor
    func switchTab() {
        let vm = PanelViewModel(client: MockRcloneClient())
        vm.left.addTab(mode: .cloud, remote: "gdrive:", label: "Drive")
        let firstId = vm.left.tabs[0].id
        vm.left.switchTab(id: firstId)
        #expect(vm.left.activeTabId == firstId)
    }

    @Test("switchTab ignores invalid ID") @MainActor
    func switchTabInvalid() {
        let vm = PanelViewModel(client: MockRcloneClient())
        let originalId = vm.left.activeTabId
        vm.left.switchTab(id: Foundation.UUID()) // non-existent
        #expect(vm.left.activeTabId == originalId)
    }
}

@Suite("PanelSideState ViewMode Tests")
struct PanelSideStateViewModeTests {
    @Test("viewMode defaults to list") @MainActor
    func viewModeDefault() {
        let vm = PanelViewModel(client: MockRcloneClient())
        #expect(vm.left.viewMode == .list)
        #expect(vm.right.viewMode == .list)
    }

    @Test("viewMode can be set to grid") @MainActor
    func viewModeSetToGrid() {
        let vm = PanelViewModel(client: MockRcloneClient())
        vm.left.viewMode = .grid
        #expect(vm.left.viewMode == .grid)
    }

    @Test("viewMode toggle between list and grid") @MainActor
    func viewModeToggle() {
        let vm = PanelViewModel(client: MockRcloneClient())
        vm.left.viewMode = vm.left.viewMode == .list ? .grid : .list
        #expect(vm.left.viewMode == .grid)
        vm.left.viewMode = vm.left.viewMode == .list ? .grid : .list
        #expect(vm.left.viewMode == .list)
    }

    @Test("viewMode independent per side") @MainActor
    func viewModeIndependent() {
        let vm = PanelViewModel(client: MockRcloneClient())
        vm.left.viewMode = .grid
        vm.right.viewMode = .list
        #expect(vm.left.viewMode == .grid)
        #expect(vm.right.viewMode == .list)
    }

    @Test("viewMode persists across tab switches") @MainActor
    func viewModePersistsAcrossTabs() {
        let vm = PanelViewModel(client: MockRcloneClient())
        vm.left.viewMode = .grid
        vm.left.addTab(mode: .cloud, remote: "gdrive:", label: "Drive")
        #expect(vm.left.viewMode == .grid)
        // Switch back to first tab
        let firstId = vm.left.tabs[0].id
        vm.left.switchTab(id: firstId)
        #expect(vm.left.viewMode == .grid)
    }
}

@Suite("PanelViewModel Selection Tests")
struct PanelViewModelSelectionTests {
    @Test("toggleSelect adds and removes") @MainActor
    func toggleSelect() {
        let vm = PanelViewModel(client: MockRcloneClient())
        vm.toggleSelect(side: .left, name: "file.txt")
        #expect(vm.left.activeTab.selectedFiles.contains("file.txt"))
        vm.toggleSelect(side: .left, name: "file.txt")
        #expect(!vm.left.activeTab.selectedFiles.contains("file.txt"))
    }

    @Test("selectAll selects all file names") @MainActor
    func selectAll() {
        let vm = PanelViewModel(client: MockRcloneClient())
        vm.left.activeTab.files = []
        vm.selectAll(side: .left)
        #expect(vm.left.activeTab.selectedFiles.isEmpty)
    }

    @Test("clearSelection empties set") @MainActor
    func clearSelection() {
        let vm = PanelViewModel(client: MockRcloneClient())
        vm.left.activeTab.selectedFiles = ["a", "b", "c"]
        vm.clearSelection(side: .left)
        #expect(vm.left.activeTab.selectedFiles.isEmpty)
    }

    @Test("singleSelect clears others and selects one") @MainActor
    func singleSelect() {
        let vm = PanelViewModel(client: MockRcloneClient())
        vm.left.activeTab.selectedFiles = ["a", "b", "c"]
        vm.singleSelect(side: .left, name: "b")
        #expect(vm.left.activeTab.selectedFiles == ["b"])
    }

    @Test("rangeSelect selects contiguous range") @MainActor
    func rangeSelect() {
        let vm = PanelViewModel(client: MockRcloneClient())
        vm.left.activeTab.files = [
            makeFileItem(name: "a", size: 1),
            makeFileItem(name: "b", size: 2),
            makeFileItem(name: "c", size: 3)
        ]
        vm.singleSelect(side: .left, name: "a")
        vm.rangeSelect(side: .left, toName: "c")
        #expect(vm.left.activeTab.selectedFiles.count == 3)
        #expect(vm.left.activeTab.selectedFiles.contains("a"))
        #expect(vm.left.activeTab.selectedFiles.contains("b"))
        #expect(vm.left.activeTab.selectedFiles.contains("c"))
    }
}

@Suite("PanelViewModel Sort Tests")
struct PanelViewModelSortTests {
    @Test("setSort changes field") @MainActor
    func setSortField() {
        let vm = PanelViewModel(client: MockRcloneClient())
        vm.setSort(side: .left, field: .size)
        #expect(vm.left.activeTab.sortBy == .size)
        #expect(vm.left.activeTab.sortAsc == true)
    }

    @Test("setSort same field toggles direction") @MainActor
    func setSortToggle() {
        let vm = PanelViewModel(client: MockRcloneClient())
        vm.setSort(side: .left, field: .name)
        #expect(vm.left.activeTab.sortAsc == false)
        vm.setSort(side: .left, field: .name)
        #expect(vm.left.activeTab.sortAsc == true)
    }

    @Test("sortedFiles puts directories first") @MainActor
    func sortedFilesDirsFirst() {
        let vm = PanelViewModel(client: MockRcloneClient())
        vm.left.activeTab.files = [
            makeFileItem(name: "zfile", size: 1),
            makeFileItem(name: "adir", isDir: true)
        ]
        let sorted = vm.left.activeTab.sortedFiles
        #expect(sorted[0].isDir == true)
        #expect(sorted[1].isDir == false)
    }
}

@Suite("PanelViewModel File Operations Tests")
struct PanelViewModelFileOpsTests {
    @Test("loadFiles populates tab") @MainActor
    func loadFiles() async {
        let mock = MockRcloneClient()
        mock.responses["operations/list"] = ["list": [
            ["Name": "test.txt", "Path": "test.txt", "Size": 100, "ModTime": "2024-01-01T00:00:00.000000000Z", "IsDir": false, "MimeType": "text/plain"]
        ]]
        let vm = PanelViewModel(client: mock)
        await vm.loadFiles(side: .left, remote: "/", path: "")
        #expect(!vm.left.activeTab.files.isEmpty)
        #expect(vm.left.activeTab.loading == false)
    }

    @Test("loadFiles sets error on failure") @MainActor
    func loadFilesError() async {
        let mock = MockRcloneClient()
        mock.errorForMethod["operations/list"] = RcloneError.rpcFailed(method: "operations/list", status: 500, message: "fail")
        let vm = PanelViewModel(client: mock)
        await vm.loadFiles(side: .left, remote: "/", path: "")
        #expect(vm.left.activeTab.error != nil)
        #expect(vm.left.activeTab.loading == false)
    }

    @Test("goUp removes last path component") @MainActor
    func goUp() async {
        let mock = MockRcloneClient()
        mock.responses["operations/list"] = ["list": []]
        let vm = PanelViewModel(client: mock)
        vm.left.activeTab.path = "a/b/c"
        await vm.goUp(side: .left)
        #expect(vm.left.activeTab.path == "a/b")
    }

    @Test("goUp from root does nothing") @MainActor
    func goUpRoot() async {
        let mock = MockRcloneClient()
        let vm = PanelViewModel(client: mock)
        vm.left.activeTab.path = ""
        await vm.goUp(side: .left)
        #expect(vm.left.activeTab.path == "")
    }

    @Test("navigate appends path") @MainActor
    func navigate() async {
        let mock = MockRcloneClient()
        mock.responses["operations/list"] = ["list": []]
        let vm = PanelViewModel(client: mock)
        vm.left.activeTab.path = "a"
        await vm.navigate(side: .left, dirName: "b")
        #expect(vm.left.activeTab.path == "a/b")
    }

    @Test("navigate from root") @MainActor
    func navigateFromRoot() async {
        let mock = MockRcloneClient()
        mock.responses["operations/list"] = ["list": []]
        let vm = PanelViewModel(client: mock)
        vm.left.activeTab.path = ""
        await vm.navigate(side: .left, dirName: "folder")
        #expect(vm.left.activeTab.path == "folder")
    }

    @Test("navigate clears selection") @MainActor
    func navigateClearsSelection() async {
        let mock = MockRcloneClient()
        mock.responses["operations/list"] = ["list": []]
        let vm = PanelViewModel(client: mock)
        vm.left.activeTab.selectedFiles = ["a", "b"]
        await vm.navigate(side: .left, dirName: "sub")
        #expect(vm.left.activeTab.selectedFiles.isEmpty)
    }

    @Test("createFolder calls mkdir") @MainActor
    func createFolder() async throws {
        let mock = MockRcloneClient()
        mock.responses["operations/mkdir"] = [:]
        mock.responses["operations/list"] = ["list": []]
        let vm = PanelViewModel(client: mock)
        try await vm.createFolder(side: .left, name: "NewFolder")
        #expect(mock.callLog.contains { $0.method == "operations/mkdir" })
    }

    @Test("setRemote configures tab") @MainActor
    func setRemote() {
        let vm = PanelViewModel(client: MockRcloneClient())
        vm.setRemote(side: .right, remote: "gdrive:")
        #expect(vm.right.activeTab.remote == "gdrive:")
        #expect(vm.right.activeTab.label == "gdrive")
        #expect(vm.right.activeTab.path == "")
        #expect(vm.right.activeTab.files.isEmpty)
    }

    @Test("navigateTo sets remote and path") @MainActor
    func navigateTo() async {
        let mock = MockRcloneClient()
        mock.responses["operations/list"] = ["list": []]
        let vm = PanelViewModel(client: mock)
        await vm.navigateTo(side: .left, remote: "s3:", path: "bucket/folder")
        #expect(vm.left.activeTab.remote == "s3:")
        #expect(vm.left.activeTab.path == "bucket/folder")
    }

    @Test("deleteSelected auto-selects adjacent file after delete") @MainActor
    func deleteSelectedAutoSelect() async throws {
        let mock = MockRcloneClient()
        mock.responses["operations/deletefile"] = [:]
        // After refresh, remaining files
        mock.responses["operations/list"] = ["list": [
            ["Name": "a.txt", "Path": "a.txt", "Size": 10, "ModTime": "2024-01-01T00:00:00.000000000Z", "IsDir": false, "MimeType": ""],
            ["Name": "c.txt", "Path": "c.txt", "Size": 30, "ModTime": "2024-01-01T00:00:00.000000000Z", "IsDir": false, "MimeType": ""]
        ]]
        let vm = PanelViewModel(client: mock)
        vm.left.activeTab.remote = "/"
        vm.left.activeTab.files = [
            makeFileItem(name: "a.txt", path: "a.txt", size: 10),
            makeFileItem(name: "b.txt", path: "b.txt", size: 20),
            makeFileItem(name: "c.txt", path: "c.txt", size: 30)
        ]
        vm.left.activeTab.selectedFiles = ["b.txt"]
        try await vm.deleteSelected(side: .left)
        // Should auto-select the file at the same index (c.txt, now at index 1)
        #expect(vm.left.activeTab.selectedFiles.count == 1)
        #expect(vm.left.activeTab.selectedFiles.contains("c.txt"))
        #expect(mock.callLog.contains { $0.method == "operations/list" })
    }

    @Test("deleteSelected auto-selects last file when deleting at end") @MainActor
    func deleteSelectedLastFile() async throws {
        let mock = MockRcloneClient()
        mock.responses["operations/deletefile"] = [:]
        mock.responses["operations/list"] = ["list": [
            ["Name": "a.txt", "Path": "a.txt", "Size": 10, "ModTime": "2024-01-01T00:00:00.000000000Z", "IsDir": false, "MimeType": ""]
        ]]
        let vm = PanelViewModel(client: mock)
        vm.left.activeTab.remote = "/"
        vm.left.activeTab.files = [
            makeFileItem(name: "a.txt", path: "a.txt", size: 10),
            makeFileItem(name: "b.txt", path: "b.txt", size: 20)
        ]
        vm.left.activeTab.selectedFiles = ["b.txt"]
        try await vm.deleteSelected(side: .left)
        // Deleted last item → select new last item
        #expect(vm.left.activeTab.selectedFiles == ["a.txt"])
    }

    @Test("deleteSelected leaves empty selection when all files deleted") @MainActor
    func deleteSelectedAllFiles() async throws {
        let mock = MockRcloneClient()
        mock.responses["operations/deletefile"] = [:]
        mock.responses["operations/list"] = ["list": []]
        let vm = PanelViewModel(client: mock)
        vm.left.activeTab.remote = "/"
        vm.left.activeTab.files = [
            makeFileItem(name: "only.txt", path: "only.txt", size: 100)
        ]
        vm.left.activeTab.selectedFiles = ["only.txt"]
        try await vm.deleteSelected(side: .left)
        #expect(vm.left.activeTab.selectedFiles.isEmpty)
    }

    @Test("deleteSelected multi-file selects adjacent") @MainActor
    func deleteSelectedMulti() async throws {
        let mock = MockRcloneClient()
        mock.responses["operations/deletefile"] = [:]
        mock.responses["operations/list"] = ["list": [
            ["Name": "d.txt", "Path": "d.txt", "Size": 40, "ModTime": "2024-01-01T00:00:00.000000000Z", "IsDir": false, "MimeType": ""]
        ]]
        let vm = PanelViewModel(client: mock)
        vm.left.activeTab.remote = "/"
        vm.left.activeTab.files = [
            makeFileItem(name: "a.txt", path: "a.txt", size: 10),
            makeFileItem(name: "b.txt", path: "b.txt", size: 20),
            makeFileItem(name: "c.txt", path: "c.txt", size: 30),
            makeFileItem(name: "d.txt", path: "d.txt", size: 40)
        ]
        vm.left.activeTab.selectedFiles = ["a.txt", "b.txt", "c.txt"]
        try await vm.deleteSelected(side: .left)
        // First selected was at index 0, only d.txt remains → select d.txt
        #expect(vm.left.activeTab.selectedFiles == ["d.txt"])
    }

    @Test("rename auto-selects renamed file") @MainActor
    func renameAutoSelect() async throws {
        let mock = MockRcloneClient()
        mock.responses["operations/movefile"] = [:]
        mock.responses["operations/list"] = ["list": [
            ["Name": "newname.txt", "Path": "newname.txt", "Size": 100, "ModTime": "2024-01-01T00:00:00.000000000Z", "IsDir": false, "MimeType": ""]
        ]]
        let vm = PanelViewModel(client: mock)
        vm.left.activeTab.remote = "/"
        vm.left.activeTab.files = [
            makeFileItem(name: "old.txt", path: "old.txt", size: 100)
        ]
        vm.left.activeTab.selectedFiles = ["old.txt"]
        try await vm.rename(side: .left, oldName: "old.txt", newName: "newname.txt")
        #expect(vm.left.activeTab.selectedFiles == ["newname.txt"])
    }

    @Test("calculateDirectorySize returns 0 for nonexistent")
    func calcDirSizeNonexistent() {
        let size = PanelViewModel.calculateDirectorySize(path: "/nonexistent_dir_12345")
        #expect(size == 0)
    }

    @Test("calculateDirectorySize works for temp dir")
    func calcDirSize() throws {
        let fm = Foundation.FileManager.default
        let tmpDir = fm.temporaryDirectory.appendingPathComponent(Foundation.UUID().uuidString)
        try fm.createDirectory(at: tmpDir, withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: tmpDir) }
        let fileURL = tmpDir.appendingPathComponent("test.dat")
        let data = Foundation.Data(repeating: 0x42, count: 1024)
        try data.write(to: fileURL)
        let size = PanelViewModel.calculateDirectorySize(path: tmpDir.path)
        #expect(size >= 1024)
    }
}

@Suite("PanelViewModel Clipboard Tests")
struct PanelViewModelClipboardTests {
    @Test("ClipboardState copy and clear") @MainActor
    func clipboardCopyAndClear() {
        let cb = ClipboardState()
        cb.copy(fs: "gdrive:", path: "docs", selectedFiles: [("file.txt", false)])
        #expect(cb.hasData)
        #expect(cb.action == .copy)
        cb.clear()
        #expect(!cb.hasData)
    }

    @Test("ClipboardState cut sets action") @MainActor
    func clipboardCut() {
        let cb = ClipboardState()
        cb.cut(fs: "/", path: "", selectedFiles: [("test.txt", false)])
        #expect(cb.action == .cut)
    }
}
