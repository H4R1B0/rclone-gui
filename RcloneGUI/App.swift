import SwiftUI

// MARK: - Notification Names (keyboard shortcuts from menu commands)

extension Notification.Name {
    static let requestRename = Notification.Name("requestRename")
    static let requestCopy = Notification.Name("requestCopy")
    static let requestCut = Notification.Name("requestCut")
    static let requestDelete = Notification.Name("requestDelete")
    static let requestNewFolder = Notification.Name("requestNewFolder")
    static let requestPaste = Notification.Name("requestPaste")
    static let requestSelectAll = Notification.Name("requestSelectAll")
    static let requestSearch = Notification.Name("requestSearch")
    static let requestQuickLook = Notification.Name("requestQuickLook")
    static let requestBookmark = Notification.Name("requestBookmark")
}

@main
struct RcloneGUIApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .task { await appState.startup() }
                .onDisappear { appState.shutdown() }
        }
        .defaultSize(width: 1400, height: 900)
        .windowResizability(.contentMinSize)
        .commands {
            CommandGroup(after: .newItem) {
                Button("New Folder...") {
                    NotificationCenter.default.post(name: .requestNewFolder, object: nil)
                }
                .keyboardShortcut("n", modifiers: [.command, .shift])
            }

            CommandGroup(replacing: .pasteboard) {
                Button("Copy") {
                    NotificationCenter.default.post(name: .requestCopy, object: nil)
                }
                .keyboardShortcut("c", modifiers: .command)

                Button("Cut") {
                    NotificationCenter.default.post(name: .requestCut, object: nil)
                }
                .keyboardShortcut("x", modifiers: .command)

                Button("Paste") {
                    NotificationCenter.default.post(name: .requestPaste, object: nil)
                }
                .keyboardShortcut("v", modifiers: .command)
            }

            CommandGroup(after: .toolbar) {
                Button("Search") {
                    NotificationCenter.default.post(name: .requestSearch, object: nil)
                }
                .keyboardShortcut("f", modifiers: .command)

                Button("Quick Look") {
                    NotificationCenter.default.post(name: .requestQuickLook, object: nil)
                }
                .keyboardShortcut(" ", modifiers: [])

                Button("Bookmark") {
                    NotificationCenter.default.post(name: .requestBookmark, object: nil)
                }
                .keyboardShortcut("d", modifiers: .command)
            }

            CommandGroup(after: .pasteboard) {
                Button("Delete") {
                    NotificationCenter.default.post(name: .requestDelete, object: nil)
                }
                .keyboardShortcut(.delete, modifiers: .command)

                Divider()

                Button("Select All") {
                    NotificationCenter.default.post(name: .requestSelectAll, object: nil)
                }
                .keyboardShortcut("a", modifiers: .command)
            }
        }
    }
}
