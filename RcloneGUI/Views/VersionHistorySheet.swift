import SwiftUI
import RcloneKit

struct FileVersion: Identifiable {
    let id = UUID()
    let name: String
    let size: Int64
    let modTime: String
    let versionId: String
    let isCurrent: Bool
}

struct VersionHistorySheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    let file: FileItem
    let fs: String

    @State private var versions: [FileVersion] = []
    @State private var isLoading = true
    @State private var error: String?

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(L10n.t("version.title")).font(.headline)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()

            Text(file.name)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            Divider()

            if isLoading {
                VersionListSkeleton()
            } else if let error = error {
                ErrorRetryView(
                    message: L10n.t("version.notSupported"),
                    detail: error,
                    onRetry: { Task { await loadVersions() } }
                )
            } else if versions.isEmpty {
                Text(L10n.t("version.noVersions")).foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(versions) { ver in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 4) {
                                    Text(ver.modTime).font(.system(size: 12))
                                    if ver.isCurrent {
                                        Text(L10n.t("version.current"))
                                            .font(.system(size: 9, weight: .bold))
                                            .padding(.horizontal, 4)
                                            .padding(.vertical, 1)
                                            .background(Color.green.opacity(0.2))
                                            .cornerRadius(3)
                                    }
                                }
                                Text("ID: \(ver.versionId.prefix(16))...")
                                    .font(.system(size: 9, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text(FormatUtils.formatBytes(ver.size))
                                .font(.system(size: 11)).foregroundColor(.secondary)
                        }
                    }
                }
                .listStyle(.inset)
            }

            HStack {
                Spacer()
                Button(L10n.t("close")) { dismiss() }.keyboardShortcut(.cancelAction)
            }
            .padding()
        }
        .frame(width: 450, height: 400)
        .task { await loadVersions() }
    }

    private func loadVersions() async {
        isLoading = true
        do {
            // Try to get versions via backend-specific API
            // rclone doesn't have a universal version API, so we use operations/stat
            // For backends like S3/B2 that support it, the stat may include version info
            let result = try await appState.client.call("operations/stat", params: [
                "fs": fs, "remote": file.path
            ])

            // Check if we got version info
            if let item = result["item"] as? [String: Any] {
                let version = FileVersion(
                    name: file.name,
                    size: item["Size"] as? Int64 ?? file.size,
                    modTime: item["ModTime"] as? String ?? "",
                    versionId: item["ID"] as? String ?? "current",
                    isCurrent: true
                )
                versions = [version]
            }
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}
