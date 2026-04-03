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
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = tab.error {
                    VStack(spacing: 12) {
                        let classified = ErrorClassifier.classify(error)
                        ErrorBannerView(classified: classified, onAction: {
                            Task { await appState.panels.refresh(side: side) }
                        }, onDismiss: nil)
                        .padding(.horizontal, 20)

                        Button(L10n.t("retry")) {
                            Task { await appState.panels.refresh(side: side) }
                        }
                        .controlSize(.small)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                      let data = jsonStr.data(using: .utf8),
                      let draggedFile = try? JSONDecoder().decode(DraggedFile.self, from: data)
                else { return false }

                let sourceSide: PanelSide = draggedFile.sideName == "left" ? .left : .right
                guard sourceSide != side else { return false }

                let isMove = NSEvent.modifierFlags.contains(.option)
                Task {
                    await appState.panels.handleDrop(
                        targetSide: side,
                        files: [draggedFile],
                        isMove: isMove
                    )
                }
                return true
            }
            .onDrop(of: [.fileURL], isTargeted: nil) { providers in
                for provider in providers {
                    _ = provider.loadObject(ofClass: URL.self) { url, _ in
                        guard let url = url else { return }
                        let fileName = url.lastPathComponent
                        let srcPath = url.path
                        Task { @MainActor in
                            let tab = appState.panels.side(side).activeTab
                            let dstRemote = tab.path.isEmpty ? fileName : "\(tab.path)/\(fileName)"
                            _ = try? await RcloneAPI.copyFileAsync(
                                using: appState.client,
                                srcFs: "/", srcRemote: srcPath,
                                dstFs: tab.remote, dstRemote: dstRemote
                            )
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
