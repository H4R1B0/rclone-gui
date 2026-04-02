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
    }
}
