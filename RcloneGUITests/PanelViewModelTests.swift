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

    @Test("goUp removes last path component") @MainActor
    func goUp() async {
        let mock = MockRcloneClient()
        mock.responses["operations/list"] = ["list": []]
        let vm = PanelViewModel(client: mock)
        vm.left.activeTab.path = "a/b/c"
        await vm.goUp(side: .left)
        #expect(vm.left.activeTab.path == "a/b")
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
}
