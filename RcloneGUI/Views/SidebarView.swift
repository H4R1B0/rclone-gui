import SwiftUI
import RcloneKit

struct SidebarView: View {
    @Environment(AppState.self) private var appState
    @Binding var selection: SidebarItem?
    @State private var remoteToDelete: Remote?
    @State private var renamingBookmarkId: UUID?
    @State private var renameText: String = ""
    @FocusState private var renameFocused: Bool

    var body: some View {
        List(selection: $selection) {
            // Favorites
            Section(L10n.t("sidebar.favorites")) {
                Label(L10n.t("toolbar.explore"), systemImage: "rectangle.split.2x1")
                    .tag(SidebarItem.explorer)

                Label(L10n.t("toolbar.search"), systemImage: "magnifyingglass")
                    .tag(SidebarItem.search)
            }

            // Cloud Remotes
            Section(L10n.t("sidebar.remotes")) {
                ForEach(appState.accounts.orderedRemotes) { remote in
                    Label {
                        VStack(alignment: .leading, spacing: 1) {
                            Text(appState.accounts.displayName(for: remote.name))
                            if appState.accounts.aliasStore.alias(for: remote.name) != nil {
                                Text(remote.name)
                                    .font(.system(size: 9))
                                    .foregroundColor(.secondary)
                            }
                        }
                    } icon: {
                        ProviderIcon.icon(for: remote.type)
                    }
                    .tag(SidebarItem.remote(remote.name))
                    .contextMenu {
                        Button(L10n.t("delete"), role: .destructive) {
                            remoteToDelete = remote
                        }
                    }
                }

                Button(action: { appState.showAccountSetup = true }) {
                    Label(L10n.t("panel.addAccount"), systemImage: "plus.circle")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }

            // Bookmarks
            if !appState.bookmarks.bookmarks.isEmpty {
                Section(L10n.t("bookmark.title")) {
                    ForEach(Array(appState.bookmarks.bookmarks.enumerated()), id: \.element.id) { index, bookmark in
                        bookmarkRow(bookmark: bookmark, index: index)
                    }
                    .onMove { offsets, destination in
                        appState.bookmarks.moveFromOffsets(offsets, to: destination)
                    }
                }
            }

            // Tools
            Section(L10n.t("sidebar.tools")) {
                Label(L10n.t("toolbar.sync"), systemImage: "arrow.triangle.2.circlepath")
                    .tag(SidebarItem.sync)

                Label(L10n.t("toolbar.scheduler"), systemImage: "clock")
                    .tag(SidebarItem.scheduler)

                Label(L10n.t("toolbar.mount"), systemImage: "externaldrive")
                    .tag(SidebarItem.mount)

                Label(L10n.t("toolbar.trash"), systemImage: "trash")
                    .tag(SidebarItem.trash)

                Label(L10n.t("duplicate.title"), systemImage: "doc.on.doc")
                    .tag(SidebarItem.duplicates)
            }
        }
        .listStyle(.sidebar)
        .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 280)
        .confirmationDialog(L10n.t("confirm.delete.title"), isPresented: Binding(
            get: { remoteToDelete != nil },
            set: { if !$0 { remoteToDelete = nil } }
        )) {
            Button(L10n.t("delete"), role: .destructive) {
                if let r = remoteToDelete {
                    Task { try? await appState.accounts.deleteRemote(name: r.name) }
                    remoteToDelete = nil
                }
            }
        } message: {
            Text(L10n.t("confirm.delete.message", remoteToDelete.map { appState.accounts.displayName(for: $0.name) } ?? ""))
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 0) {
                Divider()

                Button(action: {
                    let panel = NSOpenPanel()
                    panel.allowsMultipleSelection = true
                    panel.canChooseFiles = true
                    panel.canChooseDirectories = true
                    panel.begin { result in
                        guard result == .OK else { return }
                        NotificationCenter.default.post(name: .finderUploadRequested, object: panel.urls)
                    }
                }) {
                    Label(L10n.t("sidebar.quickUpload"), systemImage: "arrow.up.circle.fill")
                        .font(.system(size: 12))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                .foregroundColor(.accentColor)
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 4)

                HStack {
                    Image(systemName: "cloud.fill")
                        .foregroundColor(.accentColor)
                    Text(AppConstants.appName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("v\(AppConstants.appVersion)")
                        .font(.caption2)
                        .foregroundColor(.secondary.opacity(0.5))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
        }
    }
}

extension SidebarView {
    @ViewBuilder
    fileprivate func bookmarkRow(bookmark: Bookmark, index: Int) -> some View {
        let isRenaming = renamingBookmarkId == bookmark.id
        Menu {
            Button(L10n.t("bookmark.openNewTabLeft")) {
                appState.panels.left.addTab(mode: bookmark.fs == "/" ? .local : .cloud, remote: bookmark.fs, path: bookmark.path, label: bookmark.name)
                Task { await appState.panels.loadFiles(side: .left) }
            }
            Button(L10n.t("bookmark.openNewTabRight")) {
                appState.panels.right.addTab(mode: bookmark.fs == "/" ? .local : .cloud, remote: bookmark.fs, path: bookmark.path, label: bookmark.name)
                Task { await appState.panels.loadFiles(side: .right) }
            }
            Divider()
            Button(L10n.t("bookmark.rename")) {
                renameText = bookmark.name
                renamingBookmarkId = bookmark.id
                renameFocused = true
            }
            Button(L10n.t("delete"), role: .destructive) {
                appState.bookmarks.remove(id: bookmark.id)
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: bookmark.fs == "/" ? "folder" : "cloud")
                    .foregroundColor(.secondary)
                if isRenaming {
                    TextField("", text: $renameText)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 12))
                        .focused($renameFocused)
                        .onSubmit {
                            appState.bookmarks.rename(id: bookmark.id, newName: renameText)
                            renamingBookmarkId = nil
                        }
                        .onExitCommand { renamingBookmarkId = nil }
                } else {
                    VStack(alignment: .leading, spacing: 1) {
                        HStack(spacing: 4) {
                            Text(bookmark.name)
                            if index < 9 {
                                Text("⌘\(index + 1)")
                                    .font(.system(size: 9))
                                    .foregroundColor(.secondary.opacity(0.6))
                            }
                        }
                        Text(bookmark.fs == "/" ? L10n.t("panel.local") : bookmark.fs.replacingOccurrences(of: ":", with: ""))
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
    }
}

// MARK: - Remote Drag & Drop Delegate

struct RemoteDropDelegate: DropDelegate {
    let remoteName: String
    let accounts: AccountViewModel
    @Binding var draggingRemoteName: String?

    func performDrop(info: DropInfo) -> Bool {
        draggingRemoteName = nil
        return true
    }

    func dropEntered(info: DropInfo) {
        guard let from = draggingRemoteName, from != remoteName else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            accounts.moveRemote(fromName: from, toName: remoteName)
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func dropExited(info: DropInfo) {}
}
