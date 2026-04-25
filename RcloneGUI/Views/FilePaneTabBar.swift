import SwiftUI

struct FilePaneTabBar: View {
    @Environment(AppState.self) private var appState
    let side: PanelSide

    @State private var draggingTabId: UUID?

    private var sideState: PanelSideState { appState.panels.side(side) }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(sideState.tabs) { tab in
                if !tab.label.isEmpty {
                    tabItem(tab)
                        .opacity(draggingTabId == tab.id ? 0.4 : 1)
                        .onDrag {
                            draggingTabId = tab.id
                            return NSItemProvider(object: tab.id.uuidString as NSString)
                        }
                        .onDrop(of: [.text], delegate: TabDropDelegate(
                            tabId: tab.id,
                            sideState: sideState,
                            draggingTabId: $draggingTabId
                        ))
                    if tab.id != sideState.tabs.last?.id {
                        Divider().frame(height: 14)
                    }
                }
            }

            Spacer()

            Menu {
                Button(L10n.t("panel.local")) {
                    sideState.addTab(mode: .local, remote: "/", path: NSHomeDirectory(), label: L10n.t("panel.local"))
                    Task { await appState.panels.loadFiles(side: side) }
                }
                if !appState.panels.remotes.isEmpty {
                    Divider()
                    ForEach(appState.panels.remotes, id: \.self) { remote in
                        Button(remote) {
                            sideState.addTab(mode: .cloud, remote: "\(remote):", path: "", label: remote)
                            Task { await appState.panels.loadFiles(side: side) }
                        }
                    }
                }
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 10, weight: .medium))
                    .frame(width: 22, height: 22)
                    .contentShape(Rectangle())
            }
            .menuStyle(.borderlessButton)
            .frame(width: 26)
            .help(L10n.t("panel.newTab"))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.ultraThinMaterial)
    }

    private func requestCloseTab(id: UUID) {
        if appState.settings.confirmTabClose {
            let settings = appState.settings
            let alert = NSAlert()
            alert.messageText = L10n.t("tab.closeConfirm.title")
            alert.informativeText = L10n.t("tab.closeConfirm.message")
            alert.alertStyle = .warning
            alert.addButton(withTitle: L10n.t("tab.closeConfirm.close"))
            alert.addButton(withTitle: L10n.t("cancel"))
            alert.showsSuppressionButton = true
            alert.suppressionButton?.title = L10n.t("tab.closeConfirm.dontAsk")

            guard let window = NSApp.keyWindow else {
                performCloseTab(id: id)
                return
            }
            alert.beginSheetModal(for: window) { response in
                if response == .alertFirstButtonReturn {
                    if alert.suppressionButton?.state == .on {
                        settings.confirmTabClose = false
                        settings.scheduleSave()
                    }
                    self.performCloseTab(id: id)
                }
            }
        } else {
            performCloseTab(id: id)
        }
    }

    private func performCloseTab(id: UUID) {
        if sideState.tabs.count > 1 {
            sideState.closeTab(id: id)
        } else {
            sideState.resetTab(sideState.tabs[0])
        }
    }

    private func tabItem(_ tab: TabState) -> some View {
        HStack(spacing: 4) {
            if tab.mode == .local {
                Image(systemName: "internaldrive")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            } else {
                ProviderIcon.icon(for: tabRemoteType(tab))
                    .font(.system(size: 9))
            }

            Text(tab.label)
                .font(.system(size: 12))
                .lineLimit(1)

            Button(action: { requestCloseTab(id: tab.id) }) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary.opacity(0.6))
            }
            .buttonStyle(.plain)
            .help(L10n.t("panel.closeTab"))
            .opacity(sideState.activeTabId == tab.id ? 1 : 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 5)
                .fill(sideState.activeTabId == tab.id ? Color.accentColor.opacity(0.1) : Color.clear)
        )
        .contentShape(Rectangle())
        .onTapGesture { sideState.switchTab(id: tab.id) }
        .overlay {
            MiddleClickView { requestCloseTab(id: tab.id) }
        }
    }

    private func tabRemoteType(_ tab: TabState) -> String {
        let remoteName = tab.remote.replacingOccurrences(of: ":", with: "")
        return appState.accounts.remotes.first(where: { $0.name == remoteName })?.type ?? "cloud"
    }
}

// MARK: - Tab Drag & Drop Delegate

struct TabDropDelegate: DropDelegate {
    let tabId: UUID
    let sideState: PanelSideState
    @Binding var draggingTabId: UUID?

    func performDrop(info: DropInfo) -> Bool {
        draggingTabId = nil
        return true
    }

    func dropEntered(info: DropInfo) {
        guard let from = draggingTabId, from != tabId else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            sideState.moveTab(fromId: from, toId: tabId)
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func dropExited(info: DropInfo) {}
}

// MARK: - Middle Click Support

struct MiddleClickView: NSViewRepresentable {
    let action: () -> Void

    func makeNSView(context: Context) -> MiddleClickNSView {
        let view = MiddleClickNSView()
        view.action = action
        return view
    }

    func updateNSView(_ nsView: MiddleClickNSView, context: Context) {
        nsView.action = action
    }
}

final class MiddleClickNSView: NSView {
    var action: (() -> Void)?
    private var monitor: Any?

    override func hitTest(_ point: NSPoint) -> NSView? {
        return nil
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window != nil {
            if monitor == nil {
                monitor = NSEvent.addLocalMonitorForEvents(matching: .otherMouseDown) { [weak self] event in
                    guard let self = self, event.buttonNumber == 2,
                          self.window != nil else { return event }
                    let locationInView = self.convert(event.locationInWindow, from: nil)
                    if self.bounds.contains(locationInView) {
                        self.action?()
                    }
                    return event
                }
            }
        } else if let m = monitor {
            // 윈도우에서 떨어져나갈 때(creator removed/closed) 모니터 즉시 해제 — 누수 방지
            NSEvent.removeMonitor(m)
            monitor = nil
        }
    }

    override func removeFromSuperview() {
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
        super.removeFromSuperview()
    }
}
