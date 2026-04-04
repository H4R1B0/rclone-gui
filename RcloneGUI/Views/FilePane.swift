import SwiftUI
import AppKit
import UniformTypeIdentifiers
import RcloneKit

struct FilePane: View {
    @Environment(AppState.self) private var appState
    let side: PanelSide

    private var sideState: PanelSideState { appState.panels.side(side) }
    private var tab: TabState { sideState.activeTab }

    var body: some View {
        VStack(spacing: 0) {
            // Tab bar
            FilePaneTabBar(side: side)

            // Path bar
            FilePanePathBar(side: side)

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
        .onTapGesture { appState.panels.activePanel = side }
    }
}
