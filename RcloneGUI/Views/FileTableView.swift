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
    @FocusState private var isFocused: Bool

    private var tab: TabState {
        appState.panels.side(side).activeTab
    }

    var body: some View {
        VStack(spacing: 0) {
            // Column headers
            columnHeaders

            Divider()

            // File list
            if tab.sortedFiles.isEmpty && !tab.loading {
                VStack(spacing: 8) {
                    Image(systemName: "folder")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                    Text(L10n.t("panel.noFiles"))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
                .contextMenu { emptyAreaMenu }
            } else {
                // File count bar
                HStack {
                    Text(String(format: L10n.t("performance.fileCount"), tab.sortedFiles.count))
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    Spacer()
                    if tab.sortedFiles.count > 1000 {
                        Text(L10n.t("performance.largeDir"))
                            .font(.system(size: 10))
                            .foregroundColor(.orange)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 2)

                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(tab.sortedFiles) { file in
                            fileRow(file)
                        }
                    }
                    .drawingGroup()
                }
                .contextMenu { emptyAreaMenu }
            }
        }
        .focusable()
        .focused($isFocused)
        .onAppear { isFocused = true }
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
                .frame(width: 100, alignment: .trailing)

            sortButton(L10n.t("column.modified"), field: .date)
                .frame(width: 150, alignment: .trailing)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
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
                if tab.remote == "/" && isImageFile(file.name) && !file.isDir {
                    AsyncImage(url: URL(fileURLWithPath: fullLocalPath(file))) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 18, height: 18)
                                .clipShape(RoundedRectangle(cornerRadius: 2))
                        default:
                            Image(systemName: FormatUtils.fileIcon(name: file.name, isDir: file.isDir))
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                                .frame(width: 18)
                        }
                    }
                    .frame(width: 18, height: 18)
                } else {
                    Image(systemName: FormatUtils.fileIcon(name: file.name, isDir: file.isDir))
                        .font(.system(size: 14))
                        .foregroundColor(file.isDir ? .accentColor : .secondary)
                        .frame(width: 18)
                }

                if renamingFile == file.name {
                    TextField("Name", text: $renameText)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 12))
                        .onSubmit { commitRename(file) }
                        .onExitCommand { renamingFile = nil }
                } else {
                    Text(file.name)
                        .font(.system(size: 12))
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
                .frame(width: 100, alignment: .trailing)

            // Date
            Text(FormatUtils.formatDate(file.modTime))
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .frame(width: 150, alignment: .trailing)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
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
            appState.panels.toggleSelect(side: side, name: file.name)
            appState.panels.activePanel = side
        }
        .simultaneousGesture(
            TapGesture(count: 2).onEnded {
                if file.isDir {
                    Task { await appState.panels.navigate(side: side, dirName: file.name) }
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
        let sorted = tab.sortedFiles
        guard !sorted.isEmpty else { return }

        if let currentName = tab.selectedFiles.first,
           let currentIndex = sorted.firstIndex(where: { $0.name == currentName }) {
            let newIndex = max(0, min(sorted.count - 1, currentIndex + direction))
            appState.panels.clearSelection(side: side)
            appState.panels.toggleSelect(side: side, name: sorted[newIndex].name)
        } else {
            appState.panels.toggleSelect(side: side, name: sorted[0].name)
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
        let data = DraggedFile(
            sideName: side == .left ? "left" : "right",
            fileName: file.name,
            isDir: file.isDir,
            sourceFs: tab.remote,
            sourcePath: tab.path
        )
        guard let json = try? JSONEncoder().encode(data),
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

    private func fullLocalPath(_ file: FileItem) -> String {
        tab.path.isEmpty ? "/\(file.name)" : "/\(tab.path)/\(file.name)"
    }
}
