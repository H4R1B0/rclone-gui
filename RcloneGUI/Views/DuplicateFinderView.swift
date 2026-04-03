import SwiftUI
import RcloneKit

struct DuplicateFinderView: View {
    @Environment(AppState.self) private var appState
    @State private var detector: DuplicateDetector?
    @State private var selectedRemotes: Set<String> = []

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(L10n.t("duplicate.title")).font(.headline)
                Spacer()
                if let det = detector, !det.groups.isEmpty {
                    Text("\(det.groups.count) \(L10n.t("duplicate.groups")) · \(FormatUtils.formatBytes(det.totalWasted)) \(L10n.t("duplicate.wasted"))")
                        .font(.caption).foregroundColor(.secondary)
                }
            }
            .padding()

            Divider()

            if detector?.isScanning == true {
                VStack(spacing: 0) {
                    Text(detector?.progress ?? "")
                        .font(.caption).foregroundColor(.secondary)
                        .padding(.vertical, 8)
                    FileListSkeleton()
                }
            } else if let det = detector, !det.groups.isEmpty {
                // Results
                List {
                    ForEach(det.groups) { group in
                        Section {
                            ForEach(Array(group.files.enumerated()), id: \.offset) { idx, file in
                                HStack {
                                    ProviderIcon.icon(for: remoteType(file.remote))
                                        .font(.system(size: 10))
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(file.name).font(.system(size: 12))
                                        Text("\(file.remote)\(file.path)")
                                            .font(.system(size: 10))
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    if idx > 0 {  // Keep first, offer delete on rest
                                        Button(L10n.t("delete"), role: .destructive) {
                                            Task { await detector?.deleteFile(remote: file.remote, path: file.path) }
                                        }
                                        .controlSize(.mini)
                                    } else {
                                        Text(L10n.t("duplicate.keep"))
                                            .font(.system(size: 10))
                                            .foregroundColor(.green)
                                    }
                                }
                            }
                        } header: {
                            HStack {
                                Text(FormatUtils.formatBytes(group.size))
                                    .font(.system(size: 10, weight: .semibold))
                                Text("· MD5: \(group.hash.prefix(8))...")
                                    .font(.system(size: 9, design: .monospaced))
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("\(group.count) \(L10n.t("duplicate.copies"))")
                                    .font(.system(size: 10))
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                }
                .listStyle(.inset)
            } else {
                // Setup
                VStack(spacing: 16) {
                    Image(systemName: "doc.on.doc").font(.system(size: 32)).foregroundColor(.secondary)
                    Text(L10n.t("duplicate.desc")).foregroundColor(.secondary).multilineTextAlignment(.center)

                    // Remote selection
                    VStack(alignment: .leading, spacing: 4) {
                        Text(L10n.t("duplicate.selectRemotes")).font(.caption.bold())
                        ForEach(appState.accounts.remotes) { remote in
                            Toggle(remote.displayName, isOn: Binding(
                                get: { selectedRemotes.contains(remote.name) },
                                set: { if $0 { selectedRemotes.insert(remote.name) } else { selectedRemotes.remove(remote.name) } }
                            ))
                            .font(.system(size: 12))
                        }
                        Toggle(L10n.t("panel.local"), isOn: Binding(
                            get: { selectedRemotes.contains("/") },
                            set: { if $0 { selectedRemotes.insert("/") } else { selectedRemotes.remove("/") } }
                        ))
                        .font(.system(size: 12))
                    }
                    .frame(width: 250)

                    Button(L10n.t("duplicate.scan")) {
                        let det = DuplicateDetector(client: appState.client)
                        detector = det
                        Task { await det.scan(remotes: Array(selectedRemotes)) }
                    }
                    .controlSize(.large)
                    .buttonStyle(.borderedProminent)
                    .disabled(selectedRemotes.isEmpty)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private func remoteType(_ remote: String) -> String {
        let name = remote.replacingOccurrences(of: ":", with: "")
        return appState.accounts.remotes.first(where: { $0.name == name })?.type ?? "local"
    }
}
