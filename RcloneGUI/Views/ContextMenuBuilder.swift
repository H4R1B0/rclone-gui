import SwiftUI
import RcloneKit

// NOTE: Full rewrite coming in Task 9 (FileList + ContextMenu + Properties)
// Kept as a stub with Notification-based API for now.

enum ContextMenuBuilder {
    @ViewBuilder
    static func fileMenu(side: PanelSide, appState: AppState) -> some View {
        let tab = appState.panels.side(side).activeTab
        let selectedFiles = tab.files.filter { tab.selectedFiles.contains($0.name) }

        if selectedFiles.count == 1, let file = selectedFiles.first {
            if file.isDir {
                Button("Open") {
                    Task { await appState.panels.navigate(side: side, dirName: file.name) }
                }
            }

            Divider()

            Button("Rename...") {
                NotificationCenter.default.post(name: .requestRename, object: file)
            }
        }

        Button("Copy") {
            NotificationCenter.default.post(name: .requestCopy, object: Array(tab.selectedFiles))
        }
        .keyboardShortcut("c", modifiers: .command)

        Button("Cut") {
            NotificationCenter.default.post(name: .requestCut, object: Array(tab.selectedFiles))
        }
        .keyboardShortcut("x", modifiers: .command)

        Divider()

        Button("Delete", role: .destructive) {
            NotificationCenter.default.post(name: .requestDelete, object: Array(tab.selectedFiles))
        }
        .keyboardShortcut(.delete, modifiers: .command)

        Divider()

        Button("New Folder...") {
            NotificationCenter.default.post(name: .requestNewFolder, object: nil)
        }
        .keyboardShortcut("n", modifiers: [.command, .shift])
    }
}

extension Notification.Name {
    static let requestRename = Notification.Name("requestRename")
    static let requestCopy = Notification.Name("requestCopy")
    static let requestCut = Notification.Name("requestCut")
    static let requestDelete = Notification.Name("requestDelete")
    static let requestNewFolder = Notification.Name("requestNewFolder")
    static let requestPaste = Notification.Name("requestPaste")
    static let requestSelectAll = Notification.Name("requestSelectAll")
}
