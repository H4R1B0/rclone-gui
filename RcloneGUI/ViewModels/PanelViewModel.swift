import Foundation
import RcloneKit
import FileBrowser

// MARK: - Tab State

enum PanelMode: String {
    case local
    case cloud
}

enum PanelSide {
    case left
    case right
}

enum SortField: String, CaseIterable {
    case name
    case size
    case date
}

@Observable
final class TabState: Identifiable {
    let id: UUID
    var label: String
    var mode: PanelMode
    var remote: String          // "gdrive:" or "/"
    var path: String            // current directory
    var files: [FileItem] = []
    var loading: Bool = false
    var error: String?
    var selectedFiles: Set<String> = []  // file NAMES (not paths) — matches TypeScript
    var sortBy: SortField = .name
    var sortAsc: Bool = true

    init(id: UUID = UUID(), label: String, mode: PanelMode, remote: String, path: String = "") {
        self.id = id
        self.label = label
        self.mode = mode
        self.remote = remote
        self.path = path
    }

    var sortedFiles: [FileItem] {
        files.sorted { a, b in
            // Directories always first
            if a.isDir != b.isDir { return a.isDir }
            let cmp: Bool
            switch sortBy {
            case .name:
                cmp = a.name.localizedStandardCompare(b.name) == .orderedAscending
            case .size:
                cmp = a.size < b.size
            case .date:
                cmp = a.modTime < b.modTime
            }
            return sortAsc ? cmp : !cmp
        }
    }
}

// MARK: - Side State (left or right panel)

@Observable
final class PanelSideState {
    var tabs: [TabState]
    var activeTabId: UUID

    init(defaultTab: TabState) {
        self.tabs = [defaultTab]
        self.activeTabId = defaultTab.id
    }

    var activeTab: TabState {
        tabs.first { $0.id == activeTabId } ?? tabs[0]
    }

    func addTab(mode: PanelMode, remote: String, path: String = "", label: String) {
        let tab = TabState(label: label, mode: mode, remote: remote, path: path)
        tabs.append(tab)
        activeTabId = tab.id
    }

    func closeTab(id: UUID) {
        guard tabs.count > 1 else { return }
        tabs.removeAll { $0.id == id }
        if activeTabId == id {
            activeTabId = tabs[0].id
        }
    }

    func switchTab(id: UUID) {
        guard tabs.contains(where: { $0.id == id }) else { return }
        activeTabId = id
    }
}

// MARK: - Panel ViewModel (dual panel coordinator)

@Observable
final class PanelViewModel {
    let left: PanelSideState
    let right: PanelSideState
    var activePanel: PanelSide = .left

    var remotes: [String] = []
    var remotesLoading: Bool = false

    private let client: RcloneClientProtocol

    init(client: RcloneClientProtocol) {
        self.client = client
        // Default: left panel = local home, right panel = local home
        let leftTab = TabState(label: "Local", mode: .local, remote: "/", path: "")
        let rightTab = TabState(label: "Local", mode: .local, remote: "/", path: "")
        self.left = PanelSideState(defaultTab: leftTab)
        self.right = PanelSideState(defaultTab: rightTab)
    }

    func side(_ side: PanelSide) -> PanelSideState {
        side == .left ? left : right
    }

    func otherSide(_ side: PanelSide) -> PanelSideState {
        side == .left ? right : left
    }

    // MARK: - Remote Management

    @MainActor
    func loadRemotes() async {
        remotesLoading = true
        do {
            remotes = try await RcloneAPI.listRemotes(using: client)
        } catch {
            // silently fail — remotes list will be empty
        }
        remotesLoading = false
    }

    // MARK: - File Operations

    @MainActor
    func setRemote(side panelSide: PanelSide, remote: String) {
        let tab = side(panelSide).activeTab
        tab.remote = remote
        tab.path = ""
        tab.files = []
        tab.selectedFiles = []
        tab.error = nil
    }

    @MainActor
    func loadFiles(side panelSide: PanelSide, remote: String? = nil, path: String? = nil) async {
        let tab = side(panelSide).activeTab
        let fs = remote ?? tab.remote
        let dir = path ?? tab.path

        tab.loading = true
        tab.error = nil

        do {
            let items = try await RcloneAPI.listFiles(using: client, fs: fs, remote: dir)
            tab.files = items
            if let r = remote { tab.remote = r }
            if let p = path { tab.path = p }
        } catch {
            tab.error = error.localizedDescription
        }

        tab.loading = false
    }

    @MainActor
    func navigate(side panelSide: PanelSide, dirName: String) async {
        let tab = side(panelSide).activeTab
        let newPath = tab.path.isEmpty ? dirName : "\(tab.path)/\(dirName)"
        tab.selectedFiles = []
        await loadFiles(side: panelSide, path: newPath)
    }

    @MainActor
    func goUp(side panelSide: PanelSide) async {
        let tab = side(panelSide).activeTab
        guard !tab.path.isEmpty else { return }
        var parts = tab.path.split(separator: "/").map(String.init)
        parts.removeLast()
        let newPath = parts.joined(separator: "/")
        tab.selectedFiles = []
        await loadFiles(side: panelSide, path: newPath)
    }

    @MainActor
    func refresh(side panelSide: PanelSide) async {
        await loadFiles(side: panelSide)
    }

    @MainActor
    func navigateTo(side panelSide: PanelSide, remote: String, path: String) async {
        let tab = side(panelSide).activeTab
        tab.remote = remote
        tab.selectedFiles = []
        await loadFiles(side: panelSide, path: path)
    }

    // MARK: - Selection

    func toggleSelect(side panelSide: PanelSide, name: String) {
        let tab = side(panelSide).activeTab
        if tab.selectedFiles.contains(name) {
            tab.selectedFiles.remove(name)
        } else {
            tab.selectedFiles.insert(name)
        }
    }

    func selectAll(side panelSide: PanelSide) {
        let tab = side(panelSide).activeTab
        tab.selectedFiles = Set(tab.files.map(\.name))
    }

    func clearSelection(side panelSide: PanelSide) {
        side(panelSide).activeTab.selectedFiles = []
    }

    // MARK: - Sorting (TypeScript: same field → toggle direction)

    func setSort(side panelSide: PanelSide, field: SortField) {
        let tab = side(panelSide).activeTab
        if tab.sortBy == field {
            tab.sortAsc.toggle()
        } else {
            tab.sortBy = field
            tab.sortAsc = true
        }
    }

    // MARK: - File CRUD

    @MainActor
    func createFolder(side panelSide: PanelSide, name: String) async throws {
        let tab = side(panelSide).activeTab
        let fullPath = tab.path.isEmpty ? name : "\(tab.path)/\(name)"
        try await RcloneAPI.mkdir(using: client, fs: tab.remote, remote: fullPath)
        await refresh(side: panelSide)
    }

    @MainActor
    func deleteSelected(side panelSide: PanelSide) async throws {
        let tab = side(panelSide).activeTab
        for fileName in tab.selectedFiles {
            guard let file = tab.files.first(where: { $0.name == fileName }) else { continue }
            if file.isDir {
                try await RcloneAPI.purge(using: client, fs: tab.remote, remote: file.path)
            } else {
                try await RcloneAPI.deleteFile(using: client, fs: tab.remote, remote: file.path)
            }
        }
        tab.selectedFiles = []
        await refresh(side: panelSide)
    }

    @MainActor
    func rename(side panelSide: PanelSide, oldName: String, newName: String) async throws {
        let tab = side(panelSide).activeTab
        let oldPath = tab.path.isEmpty ? oldName : "\(tab.path)/\(oldName)"
        let newPath = tab.path.isEmpty ? newName : "\(tab.path)/\(newName)"
        try await RcloneAPI.moveFile(using: client, srcFs: tab.remote, srcRemote: oldPath, dstFs: tab.remote, dstRemote: newPath)
        await refresh(side: panelSide)
    }

    // MARK: - Clipboard Operations

    @MainActor
    func paste(side panelSide: PanelSide, clipboard: ClipboardState) async throws {
        let tab = side(panelSide).activeTab
        for file in clipboard.files {
            let srcRemote = clipboard.sourcePath.isEmpty ? file.name : "\(clipboard.sourcePath)/\(file.name)"
            let dstRemote = tab.path.isEmpty ? file.name : "\(tab.path)/\(file.name)"

            switch clipboard.action {
            case .cut:
                if file.isDir {
                    _ = try await RcloneAPI.moveDir(using: client, srcFs: clipboard.sourceFs, srcRemote: srcRemote, dstFs: tab.remote, dstRemote: dstRemote)
                } else {
                    _ = try await RcloneAPI.moveFileAsync(using: client, srcFs: clipboard.sourceFs, srcRemote: srcRemote, dstFs: tab.remote, dstRemote: dstRemote)
                }
            case .copy:
                if file.isDir {
                    _ = try await RcloneAPI.copyDir(using: client, srcFs: clipboard.sourceFs, srcRemote: srcRemote, dstFs: tab.remote, dstRemote: dstRemote)
                } else {
                    _ = try await RcloneAPI.copyFileAsync(using: client, srcFs: clipboard.sourceFs, srcRemote: srcRemote, dstFs: tab.remote, dstRemote: dstRemote)
                }
            case .none:
                break
            }
        }
        clipboard.clear()
        await refresh(side: panelSide)
    }
}
