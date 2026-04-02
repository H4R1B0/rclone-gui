import SwiftUI

struct ToolbarView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        HStack(spacing: 0) {
            // Left: Navigation tabs
            HStack(spacing: 2) {
                tabButton(L10n.t("toolbar.explore"), icon: "folder", view: .explore)
                tabButton(L10n.t("toolbar.accounts"), icon: "person.crop.circle", view: .account)
                tabButton(L10n.t("toolbar.search"), icon: "magnifyingglass", view: .search)
                tabButton(L10n.t("toolbar.sync"), icon: "arrow.triangle.2.circlepath", view: .sync)
                tabButton(L10n.t("toolbar.scheduler"), icon: "clock", view: .scheduler)
            }
            .padding(.horizontal, 8)

            Divider()
                .frame(height: 20)
                .padding(.horizontal, 8)

            Spacer()

            // Right: Actions (새로고침은 패널 내부 AddressBar에 있으므로 제거)
            HStack(spacing: 4) {
                Button(action: {
                    appState.showTransfers.toggle()
                }) {
                    Image(systemName: appState.showTransfers ? "arrow.up.arrow.down.circle.fill" : "arrow.up.arrow.down.circle")
                }
                .buttonStyle(.borderless)
                .help(L10n.t("toolbar.transfers"))

                Button(action: {
                    appState.showSettings.toggle()
                }) {
                    Image(systemName: "gearshape")
                }
                .buttonStyle(.borderless)
                .help(L10n.t("toolbar.settings"))
            }
            .padding(.horizontal, 8)
        }
        .padding(.vertical, 6)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private func tabButton(_ label: String, icon: String, view: ActiveView) -> some View {
        Button(action: { appState.activeView = view }) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(label)
                    .font(.system(size: 12))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(appState.activeView == view ? Color.accentColor.opacity(0.2) : Color.clear)
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }
}
