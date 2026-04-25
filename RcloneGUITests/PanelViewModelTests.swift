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

// MARK: - Task 1: History

@Suite("TabState History")
struct TabStateHistoryTests {
    @Test("pushHistory appends entry") @MainActor
    func pushAppends() {
        let tab = TabState(label: "t", mode: .cloud, remote: "gdrive:", path: "")
        tab.pushHistory(NavEntry(remote: "gdrive:", path: "A"))
        #expect(tab.backStack.count == 1)
        #expect(tab.backStack.last == NavEntry(remote: "gdrive:", path: "A"))
    }

    @Test("pushHistory ignores empty entry") @MainActor
    func pushIgnoresEmpty() {
        let tab = TabState(label: "t", mode: .cloud, remote: "gdrive:", path: "")
        tab.pushHistory(NavEntry(remote: "", path: ""))
        #expect(tab.backStack.isEmpty)
    }

    @Test("pushHistory caps at maxHistory") @MainActor
    func pushCaps() {
        let tab = TabState(label: "t", mode: .cloud, remote: "gdrive:", path: "")
        for i in 0..<(TabState.maxHistory + 5) {
            tab.pushHistory(NavEntry(remote: "gdrive:", path: "\(i)"))
        }
        #expect(tab.backStack.count == TabState.maxHistory)
        #expect(tab.backStack.first?.path == "5")
    }

    @Test("popBack returns last and pushes current to forward") @MainActor
    func popBackFlow() {
        let tab = TabState(label: "t", mode: .cloud, remote: "gdrive:", path: "B")
        tab.pushHistory(NavEntry(remote: "gdrive:", path: "A"))
        let current = NavEntry(remote: "gdrive:", path: "B")
        let result = tab.popBack(current: current)
        #expect(result == NavEntry(remote: "gdrive:", path: "A"))
        #expect(tab.backStack.isEmpty)
        #expect(tab.forwardStack.last == current)
    }

    @Test("popBack returns nil when empty") @MainActor
    func popBackEmpty() {
        let tab = TabState(label: "t", mode: .cloud, remote: "gdrive:", path: "")
        #expect(tab.popBack(current: NavEntry(remote: "gdrive:", path: "")) == nil)
    }

    @Test("popForward returns last and pushes current to back") @MainActor
    func popForwardFlow() {
        let tab = TabState(label: "t", mode: .cloud, remote: "gdrive:", path: "A")
        tab.forwardStack.append(NavEntry(remote: "gdrive:", path: "B"))
        let current = NavEntry(remote: "gdrive:", path: "A")
        let result = tab.popForward(current: current)
        #expect(result == NavEntry(remote: "gdrive:", path: "B"))
        #expect(tab.forwardStack.isEmpty)
        #expect(tab.backStack.last == current)
    }

    @Test("clearForward empties forwardStack") @MainActor
    func clearForwardEmpties() {
        let tab = TabState(label: "t", mode: .cloud, remote: "gdrive:", path: "")
        tab.forwardStack.append(NavEntry(remote: "gdrive:", path: "X"))
        tab.clearForward()
        #expect(tab.forwardStack.isEmpty)
    }

    @Test("NavEntry isEmpty true for empty strings") @MainActor
    func navEntryEmpty() {
        #expect(NavEntry(remote: "", path: "").isEmpty == true)
        #expect(NavEntry(remote: "gdrive:", path: "").isEmpty == false)
        #expect(NavEntry(remote: "", path: "A").isEmpty == false)
    }
}

// MARK: - Task 2: Visible Files

@Suite("TabState VisibleFiles")
struct TabStateVisibleFilesTests {
    @MainActor
    private func makeTab() -> TabState {
        let tab = TabState(label: "t", mode: .local, remote: "/", path: "")
        tab.files = [
            makeFileItem(name: "a.txt", path: "a.txt", size: 10),
            makeFileItem(name: ".hidden", path: ".hidden", size: 0),
            makeFileItem(name: "Report.PDF", path: "Report.PDF", size: 100),
            makeFileItem(name: "folder", path: "folder", isDir: true)
        ]
        return tab
    }

    @Test("visibleFiles hides dot-prefixed when showHidden=false") @MainActor
    func hidesDotFiles() {
        let tab = makeTab()
        let visible = tab.visibleFiles(showHidden: false)
        #expect(visible.count == 3)
        #expect(!visible.contains { $0.name == ".hidden" })
    }

    @Test("visibleFiles keeps dot-prefixed when showHidden=true") @MainActor
    func showsDotFiles() {
        let tab = makeTab()
        let visible = tab.visibleFiles(showHidden: true)
        #expect(visible.count == 4)
        #expect(visible.contains { $0.name == ".hidden" })
    }

    @Test("visibleFiles applies filterQuery case-insensitive") @MainActor
    func filterCaseInsensitive() {
        let tab = makeTab()
        tab.filterQuery = "report"
        let visible = tab.visibleFiles(showHidden: true)
        #expect(visible.count == 1)
        #expect(visible.first?.name == "Report.PDF")
    }

    @Test("visibleFiles empty filterQuery returns all") @MainActor
    func emptyFilterReturnsAll() {
        let tab = makeTab()
        tab.filterQuery = ""
        let visible = tab.visibleFiles(showHidden: true)
        #expect(visible.count == 4)
    }

    @Test("visibleFiles combines hidden + filter") @MainActor
    func combinedFilters() {
        let tab = makeTab()
        tab.filterQuery = "."
        let visible = tab.visibleFiles(showHidden: false)
        // "." matches a.txt and Report.PDF; .hidden excluded by showHidden
        #expect(visible.count == 2)
    }

    @Test("visibleFiles cache invalidates on files change") @MainActor
    func cacheInvalidatesOnFiles() {
        let tab = makeTab()
        _ = tab.visibleFiles(showHidden: true)
        tab.files = []
        let visible = tab.visibleFiles(showHidden: true)
        #expect(visible.isEmpty)
    }

    @Test("visibleFiles cache invalidates on filter change") @MainActor
    func cacheInvalidatesOnFilter() {
        let tab = makeTab()
        _ = tab.visibleFiles(showHidden: true)
        tab.filterQuery = "a"
        let visible = tab.visibleFiles(showHidden: true)
        // "a" matches a.txt (folder starts with f), Report.PDF has no 'a' — only a.txt
        #expect(visible.count == 1)
        #expect(visible.first?.name == "a.txt")
    }

    @Test("visibleFiles differs when showHidden toggles") @MainActor
    func showHiddenBoundary() {
        let tab = makeTab()
        let hidden = tab.visibleFiles(showHidden: false).count
        let shown = tab.visibleFiles(showHidden: true).count
        #expect(shown > hidden)
    }
}

@Suite("PanelSideState ShowHidden")
struct PanelSideStateShowHiddenTests {
    @Test("showHidden defaults to false") @MainActor
    func defaultFalse() {
        let vm = PanelViewModel(client: MockRcloneClient())
        #expect(vm.left.showHidden == false)
        #expect(vm.right.showHidden == false)
    }

    @Test("showHidden is independent per side") @MainActor
    func independentPerSide() {
        let vm = PanelViewModel(client: MockRcloneClient())
        vm.left.showHidden = true
        #expect(vm.left.showHidden == true)
        #expect(vm.right.showHidden == false)
    }
}

// MARK: - Task 3: History Navigation via PanelViewModel

@Suite("PanelViewModel History Navigation")
struct PanelHistoryTests {
    @MainActor
    private func makeVM() -> (PanelViewModel, MockRcloneClient) {
        let client = MockRcloneClient()
        let vm = PanelViewModel(client: client)
        vm.left.activeTab.mode = .local
        vm.left.activeTab.remote = "/"
        vm.left.activeTab.path = ""
        client.responses["operations/list"] = ["list": []]
        return (vm, client)
    }

    @Test("loadFiles pushes previous entry to history") @MainActor
    func loadPushesHistory() async {
        let (vm, _) = makeVM()
        vm.left.activeTab.path = "A"
        await vm.loadFiles(side: .left, path: "A/B")
        #expect(vm.left.activeTab.backStack.last == NavEntry(remote: "/", path: "A"))
        #expect(vm.left.activeTab.path == "A/B")
    }

    @Test("loadFiles clears forwardStack") @MainActor
    func loadClearsForward() async {
        let (vm, _) = makeVM()
        vm.left.activeTab.forwardStack.append(NavEntry(remote: "/", path: "X"))
        await vm.loadFiles(side: .left, path: "A")
        #expect(vm.left.activeTab.forwardStack.isEmpty)
    }

    @Test("loadFiles with recordHistory:false does not push") @MainActor
    func loadSkipHistory() async {
        let (vm, _) = makeVM()
        vm.left.activeTab.path = "A"
        await vm.loadFiles(side: .left, path: "B", recordHistory: false)
        #expect(vm.left.activeTab.backStack.isEmpty)
    }

    @Test("loadFiles clears filter on path change") @MainActor
    func loadClearsFilter() async {
        let (vm, _) = makeVM()
        vm.left.activeTab.filterQuery = "test"
        await vm.loadFiles(side: .left, path: "A")
        #expect(vm.left.activeTab.filterQuery == "")
    }

    @Test("goBack navigates to previous entry") @MainActor
    func goBackPrevious() async {
        let (vm, _) = makeVM()
        await vm.loadFiles(side: .left, path: "A")
        await vm.loadFiles(side: .left, path: "A/B")
        await vm.goBack(side: .left)
        #expect(vm.left.activeTab.path == "A")
        #expect(vm.left.activeTab.forwardStack.last == NavEntry(remote: "/", path: "A/B"))
    }

    @Test("goForward restores forward entry") @MainActor
    func goForwardRestores() async {
        let (vm, _) = makeVM()
        await vm.loadFiles(side: .left, path: "A")
        await vm.loadFiles(side: .left, path: "A/B")
        await vm.goBack(side: .left)
        await vm.goForward(side: .left)
        #expect(vm.left.activeTab.path == "A/B")
    }

    @Test("goBack is no-op when backStack empty") @MainActor
    func goBackNoOp() async {
        let (vm, _) = makeVM()
        let initialPath = vm.left.activeTab.path
        await vm.goBack(side: .left)
        #expect(vm.left.activeTab.path == initialPath)
    }

    @Test("new navigation after goBack clears forwardStack") @MainActor
    func newNavClearsForward() async {
        let (vm, _) = makeVM()
        await vm.loadFiles(side: .left, path: "A")
        await vm.loadFiles(side: .left, path: "A/B")
        await vm.goBack(side: .left)
        await vm.loadFiles(side: .left, path: "C")
        #expect(vm.left.activeTab.forwardStack.isEmpty)
    }

    @Test("loadFiles failure preserves history/forward/filter state") @MainActor
    func failurePreservesState() async {
        let (vm, client) = makeVM()
        // Establish a baseline state
        await vm.loadFiles(side: .left, path: "A")
        vm.left.activeTab.forwardStack.append(NavEntry(remote: "/", path: "Saved"))
        vm.left.activeTab.filterQuery = "important"
        let backBefore = vm.left.activeTab.backStack
        let forwardBefore = vm.left.activeTab.forwardStack
        let filterBefore = vm.left.activeTab.filterQuery
        let pathBefore = vm.left.activeTab.path

        // Make next call fail
        client.errorForMethod["operations/list"] = RcloneError.rpcFailed(method: "operations/list", status: 503, message: "boom")

        await vm.loadFiles(side: .left, path: "B")

        #expect(vm.left.activeTab.path == pathBefore)
        #expect(vm.left.activeTab.backStack == backBefore)
        #expect(vm.left.activeTab.forwardStack == forwardBefore)
        #expect(vm.left.activeTab.filterQuery == filterBefore)
        #expect(vm.left.activeTab.error != nil)
    }

    @Test("navigateTo across remotes records correct prev entry") @MainActor
    func navigateToCrossRemote() async {
        let (vm, _) = makeVM()
        // Start in local "/Users/foo"
        await vm.loadFiles(side: .left, path: "Users/foo")
        // Cross-remote jump to gdrive:/Documents
        await vm.navigateTo(side: .left, remote: "gdrive:", path: "Documents")
        #expect(vm.left.activeTab.remote == "gdrive:")
        #expect(vm.left.activeTab.path == "Documents")
        // Back should return to ("/", "Users/foo"), not phantom ("gdrive:", "Users/foo")
        await vm.goBack(side: .left)
        #expect(vm.left.activeTab.remote == "/")
        #expect(vm.left.activeTab.path == "Users/foo")
    }
}

@Suite("PanelViewModel Selection × Visibility")
struct PanelSelectionVisibilityTests {
    @MainActor
    private func makeVM() -> PanelViewModel {
        let vm = PanelViewModel(client: MockRcloneClient())
        let tab = vm.left.activeTab
        tab.mode = .local
        tab.remote = "/"
        tab.files = [
            makeFileItem(name: ".hidden", path: ".hidden"),
            makeFileItem(name: "a.txt", path: "a.txt"),
            makeFileItem(name: "b.txt", path: "b.txt"),
            makeFileItem(name: "c.txt", path: "c.txt"),
        ]
        return vm
    }

    @Test("selectAll skips hidden when showHidden=false") @MainActor
    func selectAllSkipsHidden() {
        let vm = makeVM()
        vm.left.showHidden = false
        vm.selectAll(side: .left)
        #expect(!vm.left.activeTab.selectedFiles.contains(".hidden"))
        #expect(vm.left.activeTab.selectedFiles.count == 3)
    }

    @Test("selectAll respects active filter") @MainActor
    func selectAllRespectsFilter() {
        let vm = makeVM()
        vm.left.showHidden = true
        vm.left.activeTab.filterQuery = "a"
        vm.selectAll(side: .left)
        #expect(vm.left.activeTab.selectedFiles == ["a.txt"])
    }

    @Test("rangeSelect operates on visible files only") @MainActor
    func rangeSelectVisibleOnly() {
        let vm = makeVM()
        vm.left.showHidden = false
        // First click a.txt
        vm.singleSelect(side: .left, name: "a.txt")
        // Then shift-click c.txt
        vm.rangeSelect(side: .left, toName: "c.txt")
        // Range should not contain .hidden, only visible files
        #expect(!vm.left.activeTab.selectedFiles.contains(".hidden"))
        #expect(vm.left.activeTab.selectedFiles == ["a.txt", "b.txt", "c.txt"])
    }
}
