import SwiftUI
import AppKit
import UniformTypeIdentifiers
import RcloneKit

struct FilePane: View {
    @Environment(AppState.self) private var appState
    let side: PanelSide

    private var sideState: PanelSideState { appState.panels.side(side) }
    private var tab: TabState { sideState.activeTab }

    @State private var showQuickFilter: Bool = false
    @FocusState private var quickFilterFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Tab bar
            FilePaneTabBar(side: side)

            // Path bar
            FilePanePathBar(side: side)

            if showQuickFilter {
                quickFilterBar
            }

            Divider()

            // Content
            ZStack {
                if tab.mode == .cloud && tab.remote.isEmpty {
                    RemoteSelectorView(side: side)
                } else if tab.loading {
                    FileListSkeleton()
                } else if let error = tab.error {
                    ErrorRetryView(
                        message: ErrorClassifier.classify(error).userMessage,
                        detail: ErrorClassifier.classify(error).suggestion,
                        onRetry: { Task { await appState.panels.refresh(side: side) } }
                    )
                } else {
                    FileTableView(side: side)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(appState.panels.activePanel == side ? Color.clear : Color(nsColor: .windowBackgroundColor).opacity(0.15))
            .clipped()
            .focusEffectDisabled()
            .dropDestination(for: String.self) { items, _ in
                guard let jsonStr = items.first,
                      let data = jsonStr.data(using: .utf8)
                else { return false }

                // Decode as array (new format) or single item (legacy)
                let draggedFiles: [DraggedFile]
                if let arr = try? JSONDecoder().decode([DraggedFile].self, from: data) {
                    draggedFiles = arr
                } else if let single = try? JSONDecoder().decode(DraggedFile.self, from: data) {
                    draggedFiles = [single]
                } else {
                    return false
                }

                guard let first = draggedFiles.first else { return false }
                let sourceSide: PanelSide = first.sideName == "left" ? .left : .right
                guard sourceSide != side else { return false }

                let isMove = NSEvent.modifierFlags.contains(.option)
                Task {
                    await appState.panels.handleDrop(
                        targetSide: side,
                        files: draggedFiles,
                        isMove: isMove
                    )
                }
                return true
            }
            .onDrop(of: [.fileURL], isTargeted: nil) { providers in
                // Collect all URLs first, then process in parallel
                for provider in providers {
                    _ = provider.loadObject(ofClass: URL.self) { url, _ in
                        guard let url = url else { return }
                        let fileName = url.lastPathComponent
                        let srcPath = url.path
                        Task { @MainActor in
                            let tab = appState.panels.side(side).activeTab
                            let dstRemote = tab.path.isEmpty ? fileName : "\(tab.path)/\(fileName)"
                            let isDir = (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
                            _ = try? await RcloneAPI.copyFileAsync(
                                using: appState.client,
                                srcFs: "/", srcRemote: srcPath,
                                dstFs: tab.remote, dstRemote: dstRemote,
                                multiThreadStreams: appState.settings.multiThreadStreams
                            )
                            appState.transfers.addCopyOrigin(group: fileName, origin: CopyOrigin(
                                srcFs: "/", srcRemote: srcPath,
                                dstFs: tab.remote, dstRemote: dstRemote, isDir: isDir
                            ))
                            await appState.panels.refresh(side: side)
                        }
                    }
                }
                return true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .requestBack)) { _ in
            guard appState.panels.activePanel == side else { return }
            Task { await appState.panels.goBack(side: side) }
        }
        .onReceive(NotificationCenter.default.publisher(for: .requestForward)) { _ in
            guard appState.panels.activePanel == side else { return }
            Task { await appState.panels.goForward(side: side) }
        }
        .onReceive(NotificationCenter.default.publisher(for: .requestToggleHidden)) { _ in
            guard appState.panels.activePanel == side else { return }
            appState.panels.side(side).showHidden.toggle()
        }
        .onReceive(NotificationCenter.default.publisher(for: .requestQuickFilter)) { _ in
            guard appState.panels.activePanel == side else { return }
            showQuickFilter = true
        }
        .onChange(of: showQuickFilter) { _, isShown in
            if isShown { quickFilterFocused = true }
        }
        .simultaneousGesture(TapGesture().onEnded { appState.panels.activePanel = side })
    }

    private var quickFilterBar: some View {
        HStack(spacing: 6) {
            Image(systemName: "line.3.horizontal.decrease.circle")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            TextField(
                L10n.t("panel.quickFilter.placeholder"),
                text: Binding(
                    get: { appState.panels.side(side).activeTab.filterQuery },
                    set: { appState.panels.side(side).activeTab.filterQuery = $0 }
                )
            )
            .textFieldStyle(.plain)
            .font(.system(size: 12))
            .focused($quickFilterFocused)
            .onSubmit { quickFilterFocused = false }
            .onExitCommand {
                if appState.panels.side(side).activeTab.filterQuery.isEmpty {
                    showQuickFilter = false
                } else {
                    appState.panels.side(side).activeTab.filterQuery = ""
                }
            }

            if !appState.panels.side(side).activeTab.filterQuery.isEmpty {
                Button(action: {
                    appState.panels.side(side).activeTab.filterQuery = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help(L10n.t("panel.quickFilter.clear"))
            }

            Button(action: {
                appState.panels.side(side).activeTab.filterQuery = ""
                showQuickFilter = false
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .help(L10n.t("close"))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(nsColor: .controlBackgroundColor))
    }
}
