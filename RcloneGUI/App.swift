import SwiftUI

@main
struct RcloneGUIApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .onAppear { appState.startup() }
                .onDisappear { appState.shutdown() }
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 1200, height: 800)
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
