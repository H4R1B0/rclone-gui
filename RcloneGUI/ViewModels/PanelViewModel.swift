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

enum ViewMode: String {
    case list
    case grid
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
    var viewMode: ViewMode = .list

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
    var maxConcurrentTransfers: Int = 4
    var multiThreadStreams: Int = 4
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

    func rangeSelect(side panelSide: PanelSide, toName: String) {
        let tab = side(panelSide).activeTab
        let sorted = tab.sortedFiles
        let names = sorted.map(\.name)

        // Find anchor (last selected item) and target
        guard let toIndex = names.firstIndex(of: toName) else { return }

        // Find the anchor: the first currently-selected item in sorted order
        let anchorIndex: Int
        if let first = names.firstIndex(where: { tab.selectedFiles.contains($0) }) {
            anchorIndex = first
        } else {
            anchorIndex = toIndex
        }

        let start = min(anchorIndex, toIndex)
        let end = max(anchorIndex, toIndex)
        let rangeNames = Set(names[start...end])
        tab.selectedFiles = rangeNames
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
        let filesToDelete = tab.selectedFiles

        // Remember position of first selected file for auto-select after delete (FTP behavior)
        let sorted = tab.sortedFiles
        let firstSelectedIndex = sorted.firstIndex { filesToDelete.contains($0.name) }

        tab.selectedFiles = []
        var lastError: Error?
        for fileName in filesToDelete {
            guard let file = tab.files.first(where: { $0.name == fileName }) else { continue }
            do {
                if let trash = trashVM {
                    // For local directories, calculate actual recursive size off main thread
                    let actualSize: Int64
                    if file.isDir && tab.remote == "/" {
                        let dirPath = file.path.hasPrefix("/") ? file.path : "/\(file.path)"
                        actualSize = await Task.detached {
                            Self.calculateDirectorySize(path: dirPath)
                        }.value
                    } else {
                        actualSize = file.size
                    }
                    try await trash.deleteToTrash(
                        fs: tab.remote,
                        path: file.path,
                        name: file.name,
                        isDir: file.isDir,
                        size: actualSize
                    )
                } else {
                    if file.isDir {
                        try await RcloneAPI.purge(using: client, fs: tab.remote, remote: file.path)
                    } else {
                        try await RcloneAPI.deleteFile(using: client, fs: tab.remote, remote: file.path)
                    }
                }
            } catch {
                lastError = error
            }
        }
        await refresh(side: panelSide)

        // Auto-select adjacent file after delete (FTP-like behavior)
        if let idx = firstSelectedIndex, !tab.sortedFiles.isEmpty {
            let newIdx = min(idx, tab.sortedFiles.count - 1)
            tab.selectedFiles = [tab.sortedFiles[newIdx].name]
        }

        if let lastError { throw lastError }
    }

    func rename(side panelSide: PanelSide, oldName: String, newName: String) async throws {
        let tab = side(panelSide).activeTab
        let oldPath = tab.path.isEmpty ? oldName : "\(tab.path)/\(oldName)"
        let newPath = tab.path.isEmpty ? newName : "\(tab.path)/\(newName)"
        try await RcloneAPI.moveFile(using: client, srcFs: tab.remote, srcRemote: oldPath, dstFs: tab.remote, dstRemote: newPath)
        await refresh(side: panelSide)
        // Auto-select renamed file (FTP-like behavior)
        tab.selectedFiles = [newName]
    }

    // MARK: - Clipboard Operations

    func paste(side panelSide: PanelSide, clipboard: ClipboardState) async throws {
        let tab = side(panelSide).activeTab
        let action = clipboard.action
        let sourceFs = clipboard.sourceFs
        let sourcePath = clipboard.sourcePath
        let filesToPaste = clipboard.files

        // Enqueue all files first so they appear in UI
        let tvm = self.transferVM
        for file in filesToPaste {
            tvm?.enqueue(QueuedTransfer(name: file.name, isDir: file.isDir))
        }

        // Launch transfers with concurrency limit — runs OFF main thread
        let maxConcurrent = self.maxConcurrentTransfers
        let mts = self.multiThreadStreams
        let c = self.client
        let dstFs = tab.remote
        let dstPath = tab.path
        await withTaskGroup(of: Void.self) { group in
            var running = 0
            for file in filesToPaste {
                if running >= maxConcurrent {
                    await group.next()
                    running -= 1
                }
                let srcRemote = sourcePath.isEmpty ? file.name : "\(sourcePath)/\(file.name)"
                let dstRemote = dstPath.isEmpty ? file.name : "\(dstPath)/\(file.name)"

                group.addTask {
                    do {
                        let jobId: Int
                        switch action {
                        case .cut:
                            if file.isDir {
                                jobId = try await RcloneAPI.moveDir(using: c, srcFs: sourceFs, srcRemote: srcRemote, dstFs: dstFs, dstRemote: dstRemote, multiThreadStreams: mts)
                            } else {
                                jobId = try await RcloneAPI.moveFileAsync(using: c, srcFs: sourceFs, srcRemote: srcRemote, dstFs: dstFs, dstRemote: dstRemote, multiThreadStreams: mts)
                            }
                        case .copy:
                            if file.isDir {
                                jobId = try await RcloneAPI.copyDir(using: c, srcFs: sourceFs, srcRemote: srcRemote, dstFs: dstFs, dstRemote: dstRemote, multiThreadStreams: mts)
                            } else {
                                jobId = try await RcloneAPI.copyFileAsync(using: c, srcFs: sourceFs, srcRemote: srcRemote, dstFs: dstFs, dstRemote: dstRemote, multiThreadStreams: mts)
                            }
                        case .none:
                            return
                        }
                        let origin = CopyOrigin(
                            srcFs: sourceFs, srcRemote: srcRemote,
                            dstFs: dstFs, dstRemote: dstRemote, isDir: file.isDir
                        )
                        await MainActor.run {
                            tvm?.addCopyOrigin(group: "job/\(jobId)", origin: origin)
                            tvm?.addCopyOrigin(group: srcRemote, origin: origin)
                            tvm?.addCopyOrigin(group: file.name, origin: origin)
                        }
                        // Wait for job to finish before releasing the concurrency slot
                        try await RcloneAPI.waitForJob(using: c, jobid: jobId)
                        // Dequeue after job completes — polling handles queued→active transition
                        await MainActor.run { tvm?.dequeue(name: file.name) }
                    } catch {
                        await MainActor.run { tvm?.dequeue(name: file.name) }
                        print("[RcloneGUI] Paste failed for \(file.name): \(error.localizedDescription)")
                    }
                }
                running += 1
            }
        }
        // Refresh destination panel
        await refresh(side: panelSide)
        // Refresh source panel after move/cut so removed files disappear
        if action == .cut {
            for ps in [PanelSide.left, PanelSide.right] {
                let t = side(ps).activeTab
                if t.remote == sourceFs {
                    await refresh(side: ps)
                }
            }
        }
        clipboard.clear()
    }

    // MARK: - Drag & Drop

    func handleDrop(targetSide: PanelSide, files: [DraggedFile], isMove: Bool) async {
        let targetTab = side(targetSide).activeTab
        let dstFs = targetTab.remote
        let dstPath = targetTab.path
        let c = self.client
        let tvm = self.transferVM

        // Enqueue all files first
        for file in files {
            tvm?.enqueue(QueuedTransfer(name: file.fileName, isDir: file.isDir))
        }

        let maxConcurrent = self.maxConcurrentTransfers
        let mts = self.multiThreadStreams
        await withTaskGroup(of: Void.self) { group in
            var running = 0
            for file in files {
                if running >= maxConcurrent {
                    await group.next()
                    running -= 1
                }
                let srcRemote = file.sourcePath.isEmpty ? file.fileName : "\(file.sourcePath)/\(file.fileName)"
                let dstRemote = dstPath.isEmpty ? file.fileName : "\(dstPath)/\(file.fileName)"

                group.addTask {
                    do {
                        let jobId: Int
                        if isMove {
                            if file.isDir {
                                jobId = try await RcloneAPI.moveDir(using: c, srcFs: file.sourceFs, srcRemote: srcRemote, dstFs: dstFs, dstRemote: dstRemote, multiThreadStreams: mts)
                            } else {
                                jobId = try await RcloneAPI.moveFileAsync(using: c, srcFs: file.sourceFs, srcRemote: srcRemote, dstFs: dstFs, dstRemote: dstRemote, multiThreadStreams: mts)
                            }
                        } else {
                            if file.isDir {
                                jobId = try await RcloneAPI.copyDir(using: c, srcFs: file.sourceFs, srcRemote: srcRemote, dstFs: dstFs, dstRemote: dstRemote, multiThreadStreams: mts)
                            } else {
                                jobId = try await RcloneAPI.copyFileAsync(using: c, srcFs: file.sourceFs, srcRemote: srcRemote, dstFs: dstFs, dstRemote: dstRemote, multiThreadStreams: mts)
                            }
                        }
                        let origin = CopyOrigin(
                            srcFs: file.sourceFs, srcRemote: srcRemote,
                            dstFs: dstFs, dstRemote: dstRemote, isDir: file.isDir
                        )
                        await MainActor.run {
                            tvm?.addCopyOrigin(group: "job/\(jobId)", origin: origin)
                            tvm?.addCopyOrigin(group: srcRemote, origin: origin)
                            tvm?.addCopyOrigin(group: file.fileName, origin: origin)
                        }
                        try await RcloneAPI.waitForJob(using: c, jobid: jobId)
                        await MainActor.run { tvm?.dequeue(name: file.fileName) }
                    } catch {
                        await MainActor.run { tvm?.dequeue(name: file.fileName) }
                        print("[RcloneGUI] Drop failed for \(file.fileName): \(error.localizedDescription)")
                    }
                }
                running += 1
            }
        }
        await refresh(side: targetSide)
        // Refresh source panel after move so removed files disappear
        if isMove {
            let sourceSide: PanelSide = targetSide == .left ? .right : .left
            await refresh(side: sourceSide)
        }
    }

    // MARK: - Helpers

    /// Calculate total size of a local directory recursively
    nonisolated static func calculateDirectorySize(path: String) -> Int64 {
        let fm = FileManager.default
        guard let enumerator = fm.enumerator(atPath: path) else { return 0 }
        var total: Int64 = 0
        while let file = enumerator.nextObject() as? String {
            let fullPath = (path as NSString).appendingPathComponent(file)
            if let attrs = try? fm.attributesOfItem(atPath: fullPath),
               let size = attrs[.size] as? Int64 {
                total += size
            }
        }
        return total
    }
}
