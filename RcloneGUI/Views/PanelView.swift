import SwiftUI
import AppKit
import UniformTypeIdentifiers
import RcloneKit

struct PanelView: View {
    @Environment(AppState.self) private var appState
    let side: PanelSide

    private var sideState: PanelSideState {
        appState.panels.side(side)
    }

    private var tab: TabState {
        sideState.activeTab
    }

    var body: some View {
        VStack(spacing: 0) {
            // Cloud mode with no remote selected → show RemoteSelector
            if tab.mode == .cloud && tab.remote.isEmpty {
                RemoteSelectorView(side: side)
            } else {
                // Tab bar
                TabBarView(side: side)

                Divider()

                // Address bar
                AddressBarView(side: side)

                Divider()

                // File content
                ZStack {
                    if tab.loading {
                        VStack(spacing: 8) {
                            ProgressView()
                                .controlSize(.large)
                            Text(L10n.t("loading"))
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    } else if let error = tab.error {
                        VStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 32))
                                .foregroundColor(.secondary)
                            Text(error)
                                .foregroundColor(.secondary)
                                .font(.caption)
                                .multilineTextAlignment(.center)
                            Button(L10n.t("retry")) {
                                Task { await appState.panels.refresh(side: side) }
                            }
                        }
                        .padding()
                    } else {
                        FileTableView(side: side)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .dropDestination(for: String.self) { items, location in
                    guard let jsonStr = items.first,
                          let data = jsonStr.data(using: .utf8),
                          let draggedFile = try? JSONDecoder().decode(DraggedFile.self, from: data)
                    else { return false }

                    // Don't drop on same panel
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
                        _ = provider.loadObject(ofClass: URL.self) { url, error in
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
        }
        .onTapGesture {
            appState.panels.activePanel = side
        }
        .background(
            appState.panels.activePanel == side
                ? Color.clear
                : Color(nsColor: .windowBackgroundColor).opacity(0.3)
        )
    }
}
