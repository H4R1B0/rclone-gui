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
                    Text("No files")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
                .contextMenu { emptyAreaMenu }
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(tab.sortedFiles) { file in
                            fileRow(file)
                        }
                    }
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
    }

    // MARK: - Column Headers

    private var columnHeaders: some View {
        HStack(spacing: 0) {
            sortButton("Name", field: .name)
                .frame(maxWidth: .infinity, alignment: .leading)

            sortButton("Size", field: .size)
                .frame(width: 100, alignment: .trailing)

            sortButton("Modified", field: .date)
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
                Image(systemName: FormatUtils.fileIcon(name: file.name, isDir: file.isDir))
                    .font(.system(size: 14))
                    .foregroundColor(file.isDir ? .accentColor : .secondary)
                    .frame(width: 18)

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
            Button("Open") {
                Task { await appState.panels.navigate(side: side, dirName: file.name) }
            }
            Divider()
        }

        Button("Cut") { performCut() }
        Button("Copy") { performCopy() }

        Divider()

        Button("Rename...") {
            renamingFile = file.name
            renameText = file.name
        }

        Button("Delete", role: .destructive) {
            // Ensure this file is selected
            if !tab.selectedFiles.contains(file.name) {
                appState.panels.toggleSelect(side: side, name: file.name)
            }
            showDeleteConfirm = true
        }

        Divider()

        Button("Properties") {
            showProperties = file
        }
    }

    // MARK: - Empty Area Context Menu

    @ViewBuilder
    private var emptyAreaMenu: some View {
        Button("Paste") {
            Task {
                try? await appState.panels.paste(side: side, clipboard: appState.clipboard)
            }
        }
        .disabled(!appState.clipboard.hasData)

        Divider()

        Button("New Folder...") {
            showNewFolder = true
        }
    }

    // MARK: - Actions

    private func performCopy() {
        let selected = tab.files.filter { tab.selectedFiles.contains($0.name) }
        appState.clipboard.copy(
            fs: tab.remote,
            path: tab.path,
            selectedFiles: selected.map { ($0.name, $0.isDir) }
        )
    }

    private func performCut() {
        let selected = tab.files.filter { tab.selectedFiles.contains($0.name) }
        appState.clipboard.cut(
            fs: tab.remote,
            path: tab.path,
            selectedFiles: selected.map { ($0.name, $0.isDir) }
        )
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
}
