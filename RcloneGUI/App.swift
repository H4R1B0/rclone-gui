import SwiftUI
import CoreSpotlight

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
    static let requestExplorer = Notification.Name("requestExplorer")
    static let requestBack = Notification.Name("requestBack")
    static let requestForward = Notification.Name("requestForward")
    static let requestToggleHidden = Notification.Name("requestToggleHidden")
    static let requestQuickFilter = Notification.Name("requestQuickFilter")
}

@main
struct RcloneGUIApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var appState = AppState()

    init() {
        let args = CommandLine.arguments
        let cliCommands: Set<String> = ["list", "ls", "remotes", "copy", "move", "mkdir", "version", "help", "--help", "-h"]
        if args.count > 1 && cliCommands.contains(args[1]) {
            let group = DispatchGroup()
            group.enter()
            Task.detached {
                defer { group.leave() }
                await CLIHandler.run(arguments: args)
            }
            group.wait()
            exit(0)
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .onOpenURL { url in
                    URLSchemeHandler.handle(url, appState: appState)
                }
                .onContinueUserActivity(CSSearchableItemActionType) { activity in
                    if let result = SpotlightIndexer.shared.handleSpotlightActivity(activity) {
                        Task { @MainActor in
                            await appState.panels.navigateTo(side: .left, remote: result.remote, path: PathUtils.parent(result.path))
                        }
                    }
                }
        }
        .defaultSize(width: 1400, height: 900)
        .windowResizability(.contentMinSize)
        .windowStyle(.hiddenTitleBar)
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
                Button("Back") {
                    NotificationCenter.default.post(name: .requestBack, object: nil)
                }
                .keyboardShortcut("[", modifiers: .command)

                Button("Forward") {
                    NotificationCenter.default.post(name: .requestForward, object: nil)
                }
                .keyboardShortcut("]", modifiers: .command)

                Divider()

                Button("Quick Filter") {
                    NotificationCenter.default.post(name: .requestQuickFilter, object: nil)
                }
                .keyboardShortcut("f", modifiers: .command)

                Button("Search") {
                    NotificationCenter.default.post(name: .requestSearch, object: nil)
                }
                .keyboardShortcut("f", modifiers: [.command, .shift])

                Button("Toggle Hidden Files") {
                    NotificationCenter.default.post(name: .requestToggleHidden, object: nil)
                }
                .keyboardShortcut(".", modifiers: .command)

                Divider()

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

        MenuBarExtra {
            MenuBarView()
                .environment(appState)
        } label: {
            Image(systemName: appState.transfers.hasActiveTransfers
                ? "arrow.up.arrow.down.circle.fill"
                : "arrow.up.arrow.down.circle")
        }
    }
}

// MARK: - AppDelegate (앱 종료 시 임시 파일 정리)

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillTerminate(_ notification: Notification) {
        try? FileManager.default.removeItem(at: AppConstants.tempDownloadDir)
    }
}
