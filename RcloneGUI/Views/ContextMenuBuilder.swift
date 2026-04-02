import SwiftUI
import RcloneKit

enum ContextMenuBuilder {
    @ViewBuilder
    static func fileMenu(selectedIDs: Set<String>, viewModel: PanelViewModel) -> some View {
        let selectedFiles = viewModel.files.filter { selectedIDs.contains($0.id) }

        if selectedFiles.count == 1, let file = selectedFiles.first {
            if file.isDir {
                Button("Open") {
                    Task { await viewModel.navigateInto(file) }
                }
            }

            Divider()

            Button("Rename...") {
                NotificationCenter.default.post(name: .requestRename, object: file)
            }
        }

        Button("Copy") {
            NotificationCenter.default.post(name: .requestCopy, object: Array(selectedIDs))
        }
        .keyboardShortcut("c", modifiers: .command)

        Button("Cut") {
            NotificationCenter.default.post(name: .requestCut, object: Array(selectedIDs))
        }
        .keyboardShortcut("x", modifiers: .command)

        Divider()

        Button("Delete", role: .destructive) {
            NotificationCenter.default.post(name: .requestDelete, object: Array(selectedIDs))
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
