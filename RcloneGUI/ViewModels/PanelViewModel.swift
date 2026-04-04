import Foundation
import UniformTypeIdentifiers
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

struct DraggedFile: Codable {
    let sideName: String  // "left" or "right"
    let fileName: String
    let isDir: Bool
    let sourceFs: String
    let sourcePath: String
}

@Observable
@MainActor
final class TabState: Identifiable {
    let id: UUID
    var label: String
    var mode: PanelMode
    var remote: String          // "gdrive:" or "/"
    var path: String            // current directory
    var files: [FileItem] = [] { didSet { _cachedSortedFiles = nil } }
    var loading: Bool = false
    var error: String?
    var selectedFiles: Set<String> = []  // file NAMES (not paths) — matches TypeScript
    var sortBy: SortField = .name { didSet { _cachedSortedFiles = nil } }
    var sortAsc: Bool = true { didSet { _cachedSortedFiles = nil } }

    private var _cachedSortedFiles: [FileItem]?

    init(id: UUID = UUID(), label: String, mode: PanelMode, remote: String, path: String = "") {
        self.id = id
        self.label = label
        self.mode = mode
        self.remote = remote
        self.path = path
    }

    var sortedFiles: [FileItem] {
        if let cached = _cachedSortedFiles { return cached }
        let sorted = computeSortedFiles()
        _cachedSortedFiles = sorted
        return sorted
    }

    private func computeSortedFiles() -> [FileItem] {
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
@MainActor
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

    func moveTab(fromId: UUID, toId: UUID) {
        guard let fromIdx = tabs.firstIndex(where: { $0.id == fromId }),
              let toIdx = tabs.firstIndex(where: { $0.id == toId }),
              fromIdx != toIdx else { return }
        tabs.move(fromOffsets: IndexSet(integer: fromIdx), toOffset: toIdx > fromIdx ? toIdx + 1 : toIdx)
    }

    func resetTab(_ tab: TabState) {
        tab.label = ""
        tab.mode = .cloud
        tab.remote = ""
        tab.path = ""
        tab.files = []
        tab.selectedFiles = []
        tab.error = nil
    }
}

// MARK: - Panel ViewModel (dual panel coordinator)

@Observable @MainActor
final class PanelViewModel {
    let left: PanelSideState
    let right: PanelSideState
    var activePanel: PanelSide = .left
    var linkedBrowsing: Bool = false

    var remotes: [String] = []
    var remotesLoading: Bool = false

    private let client: RcloneClientProtocol
    private var transferVM: TransferViewModel?
    var trashVM: TrashViewModel?
    private var isSyncingLinked = false
    private var remotesLastLoaded: Date?
    private let remotesCacheTTL: TimeInterval = AppConstants.remoteCacheTTL

    init(client: RcloneClientProtocol) {
        self.client = client
        // Default: left panel = local home, right panel = cloud selector (empty)
        let leftTab = TabState(label: L10n.t("panel.local"), mode: .local, remote: "/", path: "")
        let rightTab = TabState(label: "", mode: .cloud, remote: "", path: "")
        self.left = PanelSideState(defaultTab: leftTab)
        self.right = PanelSideState(defaultTab: rightTab)
    }

    func setTransferVM(_ vm: TransferViewModel) {
        self.transferVM = vm
    }

    func setTrashVM(_ vm: TrashViewModel) {
        self.trashVM = vm
    }

    func side(_ side: PanelSide) -> PanelSideState {
        side == .left ? left : right
    }

    func otherSide(_ side: PanelSide) -> PanelSideState {
        side == .left ? right : left
    }

    // MARK: - Remote Management

    func loadRemotes() async {
        if let last = remotesLastLoaded,
           Date().timeIntervalSince(last) < remotesCacheTTL,
           !remotes.isEmpty {
            return  // Use cached
        }
        remotesLoading = true
        do {
            remotes = try await RcloneAPI.listRemotes(using: client)
            remotesLastLoaded = Date()
        } catch {
            print("[RcloneGUI] loadRemotes failed: \(error.localizedDescription)")
        }
        remotesLoading = false
    }

    // MARK: - File Operations

    func setRemote(side panelSide: PanelSide, remote: String) {
        let tab = side(panelSide).activeTab
        tab.remote = remote
        tab.label = remote.replacingOccurrences(of: ":", with: "")
        tab.path = ""
        tab.files = []
        tab.selectedFiles = []
        tab.error = nil
    }

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
            // Index for Spotlight (background, non-blocking)
            Task.detached(priority: .background) {
                SpotlightIndexer.shared.indexFiles(remote: fs, path: dir, files: items)
            }
        } catch {
            tab.error = error.localizedDescription
        }

        tab.loading = false

        // Linked browsing: sync other panel to same path
        if linkedBrowsing && !isSyncingLinked {
            isSyncingLinked = true
            let otherSide: PanelSide = panelSide == .left ? .right : .left
            let targetPath = path ?? tab.path
            let otherTab = side(otherSide).activeTab
            if otherTab.path != targetPath {
                await loadFiles(side: otherSide, path: targetPath)
            }
            isSyncingLinked = false
        }
    }

    func navigate(side panelSide: PanelSide, dirName: String) async {
        let tab = side(panelSide).activeTab
        let newPath = tab.path.isEmpty ? dirName : "\(tab.path)/\(dirName)"
        tab.selectedFiles = []
        await loadFiles(side: panelSide, path: newPath)
    }

    func goUp(side panelSide: PanelSide) async {
        let tab = side(panelSide).activeTab
        guard !tab.path.isEmpty else { return }
        var parts = tab.path.split(separator: "/").map(String.init)
        parts.removeLast()
        let newPath = parts.joined(separator: "/")
        tab.selectedFiles = []
        await loadFiles(side: panelSide, path: newPath)
    }

    func refresh(side panelSide: PanelSide) async {
        await loadFiles(side: panelSide)
    }

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

    func singleSelect(side panelSide: PanelSide, name: String) {
        let tab = side(panelSide).activeTab
        tab.selectedFiles = [name]
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

    func createFolder(side panelSide: PanelSide, name: String) async throws {
        let tab = side(panelSide).activeTab
        let fullPath = tab.path.isEmpty ? name : "\(tab.path)/\(name)"
        try await RcloneAPI.mkdir(using: client, fs: tab.remote, remote: fullPath)
        await refresh(side: panelSide)
    }

    func deleteSelected(side panelSide: PanelSide) async throws {
        let tab = side(panelSide).activeTab
        for fileName in tab.selectedFiles {
            guard let file = tab.files.first(where: { $0.name == fileName }) else { continue }
            if let trash = trashVM {
                try await trash.deleteToTrash(
                    fs: tab.remote,
                    path: file.path,
                    name: file.name,
                    isDir: file.isDir,
                    size: file.isDir ? 0 : file.size
                )
            } else {
                if file.isDir {
                    try await RcloneAPI.purge(using: client, fs: tab.remote, remote: file.path)
                } else {
                    try await RcloneAPI.deleteFile(using: client, fs: tab.remote, remote: file.path)
                }
            }
        }
        tab.selectedFiles = []
        await refresh(side: panelSide)
    }

    func rename(side panelSide: PanelSide, oldName: String, newName: String) async throws {
        let tab = side(panelSide).activeTab
        let oldPath = tab.path.isEmpty ? oldName : "\(tab.path)/\(oldName)"
        let newPath = tab.path.isEmpty ? newName : "\(tab.path)/\(newName)"
        try await RcloneAPI.moveFile(using: client, srcFs: tab.remote, srcRemote: oldPath, dstFs: tab.remote, dstRemote: newPath)
        await refresh(side: panelSide)
    }

    // MARK: - Clipboard Operations

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
                transferVM?.addCopyOrigin(group: file.name, origin: CopyOrigin(
                    srcFs: clipboard.sourceFs, srcRemote: srcRemote,
                    dstFs: tab.remote, dstRemote: dstRemote, isDir: file.isDir
                ))
            case .copy:
                if file.isDir {
                    _ = try await RcloneAPI.copyDir(using: client, srcFs: clipboard.sourceFs, srcRemote: srcRemote, dstFs: tab.remote, dstRemote: dstRemote)
                } else {
                    _ = try await RcloneAPI.copyFileAsync(using: client, srcFs: clipboard.sourceFs, srcRemote: srcRemote, dstFs: tab.remote, dstRemote: dstRemote)
                }
                transferVM?.addCopyOrigin(group: file.name, origin: CopyOrigin(
                    srcFs: clipboard.sourceFs, srcRemote: srcRemote,
                    dstFs: tab.remote, dstRemote: dstRemote, isDir: file.isDir
                ))
            case .none:
                break
            }
        }
        clipboard.clear()
        await refresh(side: panelSide)
    }

    // MARK: - Drag & Drop

    func handleDrop(targetSide: PanelSide, files: [DraggedFile], isMove: Bool) async {
        let targetTab = side(targetSide).activeTab
        for file in files {
            let srcRemote = file.sourcePath.isEmpty ? file.fileName : "\(file.sourcePath)/\(file.fileName)"
            let dstRemote = targetTab.path.isEmpty ? file.fileName : "\(targetTab.path)/\(file.fileName)"
            do {
                if isMove {
                    if file.isDir {
                        _ = try await RcloneAPI.moveDir(using: client, srcFs: file.sourceFs, srcRemote: srcRemote, dstFs: targetTab.remote, dstRemote: dstRemote)
                    } else {
                        _ = try await RcloneAPI.moveFileAsync(using: client, srcFs: file.sourceFs, srcRemote: srcRemote, dstFs: targetTab.remote, dstRemote: dstRemote)
                    }
                } else {
                    if file.isDir {
                        _ = try await RcloneAPI.copyDir(using: client, srcFs: file.sourceFs, srcRemote: srcRemote, dstFs: targetTab.remote, dstRemote: dstRemote)
                    } else {
                        _ = try await RcloneAPI.copyFileAsync(using: client, srcFs: file.sourceFs, srcRemote: srcRemote, dstFs: targetTab.remote, dstRemote: dstRemote)
                    }
                }
                transferVM?.addCopyOrigin(group: file.fileName, origin: CopyOrigin(
                    srcFs: file.sourceFs, srcRemote: srcRemote,
                    dstFs: targetTab.remote, dstRemote: dstRemote, isDir: file.isDir
                ))
            } catch {
                print("[RcloneGUI] Drop failed for \(file.fileName): \(error.localizedDescription)")
            }
        }
        await refresh(side: targetSide)
    }
}
