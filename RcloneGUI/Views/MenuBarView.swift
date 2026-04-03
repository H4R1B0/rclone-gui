import SwiftUI

struct MenuBarView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if appState.transfers.hasActiveTransfers {
                Text("\(appState.transfers.transfers.count) \(L10n.t("menubar.activeTransfers"))")
                    .font(.headline)
                Text(FormatUtils.formatSpeed(appState.transfers.totalSpeed))
                    .font(.caption)
                    .foregroundColor(.secondary)
                Divider()
            } else {
                Text(L10n.t("menubar.noTransfers"))
                    .foregroundColor(.secondary)
                Divider()
            }

            Button(L10n.t("menubar.openWindow")) {
                NSApp.activate(ignoringOtherApps: true)
                if let window = NSApp.windows.first(where: { $0.title.contains("RcloneGUI") || $0.isKeyWindow }) {
                    window.makeKeyAndOrderFront(nil)
                } else {
                    NSApp.activate(ignoringOtherApps: true)
                }
            }

            Divider()

            Button(L10n.t("menubar.quit")) {
                appState.shutdown()
                NSApp.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        .padding(8)
        .frame(width: 200)
    }
}
