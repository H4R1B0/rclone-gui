import SwiftUI
import RcloneKit

struct FileTableView: View {
    @Environment(AppState.self) private var appState
    let side: PanelSide

    @State private var showNewFolder = false
    @State private var showDeleteConfirm = false
    @State private var showProperties: FileItem?
    @State private var renamingFile: String? // file name being renamed
    @State private var renameText = ""
    @State private var quickLookURL: URL?
    @State private var showBulkRename = false
    @State private var hashCompareFiles: (FileItem, FileItem)?
    @State private var showCompress = false
    @State private var mediaFile: FileItem?
    @State private var versionFile: FileItem?
    @FocusState private var listFocused: Bool

    private var tab: TabState {
        appState.panels.side(side).activeTab
    }

    private var viewMode: ViewMode { appState.panels.side(side).viewMode }

    private let gridColumns = [GridItem(.adaptive(minimum: 90, maximum: 120), spacing: 8)]

    var body: some View {
        let showHidden = appState.panels.side(side).showHidden
        let visibleFiles = tab.visibleFiles(showHidden: showHidden)
        let hasFilter = !tab.filterQuery.isEmpty

        return VStack(spacing: 0) {
            // Column headers (list mode only)
            if viewMode == .list {
                columnHeaders
                Divider()
            }

            // File list
            if visibleFiles.isEmpty && !tab.loading {
                if hasFilter {
                    VStack(spacing: 8) {
                        ContentUnavailableView(
                            L10n.t("panel.quickFilter.noMatch"),
                            systemImage: "line.3.horizontal.decrease.circle"
                        )
                        Button(L10n.t("panel.quickFilter.clear")) {
                            tab.filterQuery = ""
                        }
                        .controlSize(.small)
                    }
                    .contentShape(Rectangle())
                    .contextMenu { emptyAreaMenu }
                } else {
                    ContentUnavailableView(L10n.t("panel.noFiles"), systemImage: "folder")
                        .contentShape(Rectangle())
                        .contextMenu { emptyAreaMenu }
                }
            } else {
                // File count bar
                HStack {
                    Text(hasFilter
                         ? L10n.t("panel.quickFilter.count",
                                  String(visibleFiles.count),
                                  String(tab.files.count))
                         : String(format: L10n.t("performance.fileCount"), visibleFiles.count))
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    Spacer()
                    if visibleFiles.count > 1000 {
                        Text(L10n.t("performance.largeDir"))
                            .font(.system(size: 11))
                            .foregroundColor(.orange)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 3)

                Group {
                    if viewMode == .grid {
                        ScrollView {
                            LazyVGrid(columns: gridColumns, spacing: 8) {
                                ForEach(visibleFiles) { file in
                                    gridCell(file)
                                }
                            }
                            .padding(8)
                        }
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                ForEach(visibleFiles) { file in
                                    fileRow(file)
                                }
                            }
                        }
                    }
                }
                .focusable()
                .focused($listFocused)
                .onKeyPress(.return) {
                    if let fileName = tab.selectedFiles.first,
                       let file = tab.files.first(where: { $0.name == fileName }) {
                        if file.isDir {
                            Task { await appState.panels.navigate(side: side, dirName: file.name) }
                        } else {
                            renamingFile = file.name
                            renameText = file.name
                        }
                    }
                    return .handled
                }
                .onKeyPress(.delete) {
                    if !tab.selectedFiles.isEmpty {
                        showDeleteConfirm = true
                    }
                    return .handled
                }
                .onKeyPress(.upArrow) {
                    selectAdjacentFile(direction: -1)
                    return .handled
                }
                .onKeyPress(.downArrow) {
                    selectAdjacentFile(direction: 1)
                    return .handled
                }
                .onKeyPress(.leftArrow) {
                    Task { await appState.panels.goUp(side: side) }
                    return .handled
                }
                .onKeyPress(.rightArrow) {
                    if let fileName = tab.selectedFiles.first,
                       let file = tab.files.first(where: { $0.name == fileName }),
                       file.isDir {
                        Task { await appState.panels.navigate(side: side, dirName: file.name) }
                    }
                    return .handled
                }
                .onKeyPress(.space) {
                    handleQuickLook()
                    return .handled
                }
                .onKeyPress(.tab) {
                    appState.panels.activePanel = (side == .left) ? .right : .left
                    return .handled
                }
                .contextMenu { emptyAreaMenu }
            }
        }
        .sheet(isPresented: $showNewFolder) {
            NewFolderSheet(side: side)
        }
        .sheet(isPresented: $showDeleteConfirm) {
            ConfirmDeleteSheet(side: side)
        }
        .sheet(item: $showProperties) { file in
            PropertiesSheet(file: file, side: side)
        }
        .sheet(isPresented: $showBulkRename) {
            BulkRenameSheet(side: side)
        }
        .sheet(isPresented: $showCompress) {
            CompressUploadSheet(side: side)
        }
        .sheet(item: Binding(
            get: { hashCompareFiles.map { HashCompareData(file1: $0.0, file2: $0.1) } },
            set: { _ in hashCompareFiles = nil }
        )) { data in
            HashCompareSheet(file1: data.file1, file1Fs: tab.remote, file2: data.file2, file2Fs: tab.remote)
        }
        .sheet(isPresented: Binding(
            get: { quickLookURL != nil },
            set: { if !$0 { quickLookURL = nil } }
        )) {
            if let url = quickLookURL {
                QuickLookPreview(url: url)
                    .frame(width: 600, height: 500)
            }
        }
        .sheet(item: $mediaFile) { file in
            MediaPlayerSheet(file: file, fs: tab.remote)
        }
        .sheet(item: $versionFile) { file in
            VersionHistorySheet(file: file, fs: tab.remote)
        }
        .onReceive(NotificationCenter.default.publisher(for: .requestQuickLook)) { _ in
            guard appState.panels.activePanel == side else { return }
            handleQuickLook()
        }
        .onReceive(NotificationCenter.default.publisher(for: .requestCopy)) { _ in
            guard appState.panels.activePanel == side else { return }
            let selected = tab.files.filter { tab.selectedFiles.contains($0.name) }
            guard !selected.isEmpty else { return }
            appState.clipboard.copy(
                fs: tab.remote,
                path: tab.path,
                selectedFiles: selected.map { ($0.name, $0.isDir) }
            )
        }
        .onReceive(NotificationCenter.default.publisher(for: .requestCut)) { _ in
            guard appState.panels.activePanel == side else { return }
            let selected = tab.files.filter { tab.selectedFiles.contains($0.name) }
            guard !selected.isEmpty else { return }
            appState.clipboard.cut(
                fs: tab.remote,
                path: tab.path,
                selectedFiles: selected.map { ($0.name, $0.isDir) }
            )
        }
        .onReceive(NotificationCenter.default.publisher(for: .requestPaste)) { _ in
            guard appState.panels.activePanel == side else { return }
            guard appState.clipboard.hasData else { return }
            Task {
                try? await appState.panels.paste(side: side, clipboard: appState.clipboard)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .requestDelete)) { _ in
            guard appState.panels.activePanel == side else { return }
            guard !tab.selectedFiles.isEmpty else { return }
            showDeleteConfirm = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .requestSelectAll)) { _ in
            guard appState.panels.activePanel == side else { return }
            appState.panels.selectAll(side: side)
        }
        .onReceive(NotificationCenter.default.publisher(for: .requestNewFolder)) { _ in
            guard appState.panels.activePanel == side else { return }
            showNewFolder = true
        }
    }

    // MARK: - Column Headers

    private var columnHeaders: some View {
        HStack(spacing: 0) {
            sortButton(L10n.t("column.name"), field: .name)
                .frame(maxWidth: .infinity, alignment: .leading)

            sortButton(L10n.t("column.size"), field: .size)
                .frame(width: 90, alignment: .trailing)

            sortButton(L10n.t("column.modified"), field: .date)
                .frame(width: 140, alignment: .trailing)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(nsColor: .controlBackgroundColor))
        .font(.system(size: 11, weight: .medium))
    }

    private func sortButton(_ label: String, field: SortField) -> some View {
        Button(action: { appState.panels.setSort(side: side, field: field) }) {
            HStack(spacing: 2) {
                Text(label)
                if tab.sortBy == field {
                    Image(systemName: tab.sortAsc ? "chevron.up" : "chevron.down")
                        .font(.system(size: 8))
                }
            }
        }
        .buttonStyle(.plain)
        .foregroundColor(tab.sortBy == field ? .primary : .secondary)
    }

    // MARK: - File Row

    private func fileRow(_ file: FileItem) -> some View {
        let isSelected = tab.selectedFiles.contains(file.name)

        return HStack(spacing: 0) {
            // Icon + Name
            HStack(spacing: 6) {
                if isThumbnailable(file) {
                    ThumbnailImageView(file: file, fs: tab.remote, size: 16, cornerRadius: 2)
                } else {
                    Image(systemName: FormatUtils.fileIcon(name: file.name, isDir: file.isDir))
                        .font(.system(size: 13))
                        .foregroundColor(file.isDir ? .accentColor : .secondary)
                        .frame(width: 16)
                }

                if renamingFile == file.name {
                    TextField("Name", text: $renameText)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 13))
                        .onSubmit { commitRename(file) }
                        .onExitCommand { renamingFile = nil }
                } else {
                    Text(file.name)
                        .font(.system(size: 13))
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Size
            Text(file.isDir ? "-" : FormatUtils.formatBytes(file.size))
                .font(.system(size: 11))
                .monospacedDigit()
                .foregroundColor(.secondary)
                .frame(width: 90, alignment: .trailing)

            // Date
            Text(FormatUtils.formatDate(file.modTime))
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .frame(width: 140, alignment: .trailing)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 5)
        .background(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
        .contentShape(Rectangle())
        .draggable(dragData(for: file)) {
            // Drag preview
            HStack(spacing: 4) {
                Image(systemName: FormatUtils.fileIcon(name: file.name, isDir: file.isDir))
                Text(file.name)
                    .font(.system(size: 12))
            }
            .padding(4)
        }
        .onTapGesture {
            if NSEvent.modifierFlags.contains(.shift) {
                appState.panels.rangeSelect(side: side, toName: file.name)
            } else if NSEvent.modifierFlags.contains(.command) {
                appState.panels.toggleSelect(side: side, name: file.name)
            } else {
                appState.panels.singleSelect(side: side, name: file.name)
            }
            appState.panels.activePanel = side
            listFocused = true
        }
        .simultaneousGesture(
            TapGesture(count: 2).onEnded {
                if file.isDir {
                    Task { await appState.panels.navigate(side: side, dirName: file.name) }
                } else if isMediaFile(file.name) && tab.remote != "/" {
                    // 클라우드 미디어는 스트리밍 우선 — MediaPlayerSheet가 백엔드 네이티브 URL/publicLink/다운로드 순으로 시도
                    mediaFile = file
                } else if isImageFile(file.name) || isMediaFile(file.name) {
                    openWithDefaultApp(file)
                }
            }
        )
        .contextMenu { fileContextMenu(file) }
    }

    // MARK: - Grid Cell

    private func gridCell(_ file: FileItem) -> some View {
        let isSelected = tab.selectedFiles.contains(file.name)

        return VStack(spacing: 4) {
            if isThumbnailable(file) {
                ThumbnailImageView(file: file, fs: tab.remote, size: 56, cornerRadius: 4)
            } else {
                Image(systemName: FormatUtils.fileIcon(name: file.name, isDir: file.isDir))
                    .font(.system(size: 28))
                    .foregroundColor(file.isDir ? .accentColor : .secondary)
                    .frame(width: 56, height: 56)
            }

            if renamingFile == file.name {
                TextField("Name", text: $renameText)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 10))
                    .multilineTextAlignment(.center)
                    .frame(width: 80)
                    .onSubmit { commitRename(file) }
                    .onExitCommand { renamingFile = nil }
            } else {
                Text(file.name)
                    .font(.system(size: 10))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(width: 80)
            }
        }
        .padding(6)
        .background(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
        .cornerRadius(6)
        .contentShape(Rectangle())
        .onTapGesture {
            if NSEvent.modifierFlags.contains(.shift) {
                appState.panels.rangeSelect(side: side, toName: file.name)
            } else if NSEvent.modifierFlags.contains(.command) {
                appState.panels.toggleSelect(side: side, name: file.name)
            } else {
                appState.panels.singleSelect(side: side, name: file.name)
            }
            appState.panels.activePanel = side
            listFocused = true
        }
        .simultaneousGesture(
            TapGesture(count: 2).onEnded {
                if file.isDir {
                    Task { await appState.panels.navigate(side: side, dirName: file.name) }
                } else if isMediaFile(file.name) && tab.remote != "/" {
                    // 클라우드 미디어는 스트리밍 우선 — MediaPlayerSheet가 백엔드 네이티브 URL/publicLink/다운로드 순으로 시도
                    mediaFile = file
                } else if isImageFile(file.name) || isMediaFile(file.name) {
                    openWithDefaultApp(file)
                }
            }
        )
        .contextMenu { fileContextMenu(file) }
    }

    // MARK: - File Context Menu

    @ViewBuilder
    private func fileContextMenu(_ file: FileItem) -> some View {
        if file.isDir {
            Button(L10n.t("file.open")) {
                Task { await appState.panels.navigate(side: side, dirName: file.name) }
            }
            Divider()
        }

        Button(L10n.t("file.cut")) { performClipboardAction(.cut) }
        Button(L10n.t("file.copy")) { performClipboardAction(.copy) }

        Divider()

        Button(L10n.t("file.rename")) {
            renamingFile = file.name
            renameText = file.name
        }

        Button(L10n.t("file.delete"), role: .destructive) {
            // Ensure this file is selected
            if !tab.selectedFiles.contains(file.name) {
                appState.panels.toggleSelect(side: side, name: file.name)
            }
            showDeleteConfirm = true
        }

        Divider()

        if tab.selectedFiles.count >= 2 {
            Button(L10n.t("bulkRename.title")) {
                showBulkRename = true
            }

            let selectedItems = tab.files.filter { tab.selectedFiles.contains($0.name) && !$0.isDir }
            if selectedItems.count == 2 {
                Button(L10n.t("hash.compare")) {
                    hashCompareFiles = (selectedItems[0], selectedItems[1])
                }
            }

            Divider()
        }

        if isMediaFile(file.name) && !file.isDir {
            Button(L10n.t("media.play")) {
                mediaFile = file
            }
        }

        Button(L10n.t("file.properties")) {
            showProperties = file
        }

        if !file.isDir {
            Button(L10n.t("version.title")) {
                versionFile = file
            }
        }

        if tab.remote == "/" && !tab.selectedFiles.isEmpty {
            Divider()
            Button(L10n.t("compress.title")) { showCompress = true }
        }

        if tab.remote != "/" && !file.isDir {
            Button(L10n.t("file.shareLink")) {
                Task {
                    if let url = try? await RcloneAPI.publicLink(using: appState.client, fs: tab.remote, remote: file.path) {
                        if !url.isEmpty {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(url, forType: .string)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Empty Area Context Menu

    @ViewBuilder
    private var emptyAreaMenu: some View {
        Button(L10n.t("file.paste")) {
            Task {
                try? await appState.panels.paste(side: side, clipboard: appState.clipboard)
            }
        }
        .disabled(!appState.clipboard.hasData)

        Divider()

        Button(L10n.t("file.newFolder")) {
            showNewFolder = true
        }
    }

    // MARK: - Actions

    private func selectAdjacentFile(direction: Int) {
        let showHidden = appState.panels.side(side).showHidden
        let visible = tab.visibleFiles(showHidden: showHidden)
        guard !visible.isEmpty else { return }

        if let currentName = tab.selectedFiles.first,
           let currentIndex = visible.firstIndex(where: { $0.name == currentName }) {
            let newIndex = max(0, min(visible.count - 1, currentIndex + direction))
            appState.panels.clearSelection(side: side)
            appState.panels.toggleSelect(side: side, name: visible[newIndex].name)
        } else {
            appState.panels.toggleSelect(side: side, name: visible[0].name)
        }
    }

    private func handleQuickLook() {
        guard tab.remote == "/" else { return }  // Only local files
        guard let fileName = tab.selectedFiles.first,
              let file = tab.files.first(where: { $0.name == fileName }),
              !file.isDir
        else { return }
        let fullPath = tab.path.isEmpty ? "/\(file.name)" : "/\(tab.path)/\(file.name)"
        quickLookURL = URL(fileURLWithPath: fullPath)
    }

    private func performClipboardAction(_ action: ClipboardState.Action) {
        let selected = tab.files.filter { tab.selectedFiles.contains($0.name) }
        let files = selected.map { ($0.name, $0.isDir) }
        switch action {
        case .copy:
            appState.clipboard.copy(fs: tab.remote, path: tab.path, selectedFiles: files)
        case .cut:
            appState.clipboard.cut(fs: tab.remote, path: tab.path, selectedFiles: files)
        }
    }

    private func dragData(for file: FileItem) -> String {
        // If the dragged file is part of a multi-selection, include all selected files
        let filesToDrag: [FileItem]
        if tab.selectedFiles.contains(file.name) && tab.selectedFiles.count > 1 {
            filesToDrag = tab.files.filter { tab.selectedFiles.contains($0.name) }
        } else {
            filesToDrag = [file]
        }
        let items = filesToDrag.map {
            DraggedFile(
                sideName: side == .left ? "left" : "right",
                fileName: $0.name,
                isDir: $0.isDir,
                sourceFs: tab.remote,
                sourcePath: tab.path
            )
        }
        guard let json = try? JSONEncoder().encode(items),
              let str = String(data: json, encoding: .utf8) else { return "" }
        return str
    }

    private func commitRename(_ file: FileItem) {
        let newName = renameText.trimmingCharacters(in: .whitespaces)
        guard !newName.isEmpty, newName != file.name else {
            renamingFile = nil
            return
        }
        Task {
            try? await appState.panels.rename(side: side, oldName: file.name, newName: newName)
            renamingFile = nil
        }
    }

    // MARK: - Thumbnail Helpers

    private func isMediaFile(_ name: String) -> Bool {
        let ext = (name as NSString).pathExtension.lowercased()
        return ["mp4", "mkv", "avi", "mov", "webm", "flv", "wmv",
                "mp3", "wav", "flac", "aac", "ogg", "wma", "m4a", "m4v"].contains(ext)
    }

    private func isImageFile(_ name: String) -> Bool {
        let ext = (name as NSString).pathExtension.lowercased()
        return ["jpg", "jpeg", "png", "gif", "bmp", "tiff", "webp", "heic"].contains(ext)
    }

    private func isVideoFile(_ name: String) -> Bool {
        let ext = (name as NSString).pathExtension.lowercased()
        return ["mp4", "mkv", "avi", "mov", "webm", "flv", "wmv", "m4v"].contains(ext)
    }

    /// 썸네일 미리보기 대상 파일 — 이미지·동영상.
    /// 클라우드 파일은 ThumbnailCache가 크기 제한을 추가로 검사하므로 여기서는 통과시킴.
    private func isThumbnailable(_ file: FileItem) -> Bool {
        guard !file.isDir else { return false }
        return isImageFile(file.name) || isVideoFile(file.name)
    }

    private func fullLocalPath(_ file: FileItem) -> String {
        tab.path.isEmpty ? "/\(file.name)" : "/\(tab.path)/\(file.name)"
    }

    private func openWithDefaultApp(_ file: FileItem) {
        if tab.mode == .local {
            let path = fullLocalPath(file)
            NSWorkspace.shared.open(URL(fileURLWithPath: path))
        } else {
            // Cloud file — async download to temp with transfer bar progress, then open
            Task {
                let tempFile = AppConstants.tempDownloadDir.appendingPathComponent(file.name)
                do {
                    let jobId = try await RcloneAPI.copyFileAsync(
                        using: appState.client,
                        srcFs: tab.remote, srcRemote: file.path,
                        dstFs: "/", dstRemote: tempFile.path
                    )
                    let origin = CopyOrigin(
                        srcFs: tab.remote, srcRemote: file.path,
                        dstFs: "/", dstRemote: tempFile.path, isDir: false
                    )
                    appState.transfers.addCopyOrigin(group: "job/\(jobId)", origin: origin)
                    appState.transfers.addCopyOrigin(group: file.path, origin: origin)
                    appState.transfers.addCopyOrigin(group: file.name, origin: origin)

                    try await RcloneAPI.waitForJob(using: appState.client, jobid: jobId)
                    _ = await MainActor.run {
                        NSWorkspace.shared.open(tempFile)
                    }
                } catch {
                    #if DEBUG
                    print("[RcloneGUI] Failed to open file: \(error)")
                    #endif
                }
            }
        }
    }
}
