import SwiftUI
import RcloneKit

struct HashCompareData: Identifiable {
    let id = UUID()
    let file1: FileItem
    let file2: FileItem
}

struct HashCompareSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    let file1: FileItem
    let file1Fs: String
    let file2: FileItem
    let file2Fs: String

    @State private var hash1: [String: String] = [:]
    @State private var hash2: [String: String] = [:]
    @State private var isLoading = true

    var body: some View {
        VStack(spacing: 16) {
            Text(L10n.t("hash.compareTitle")).font(.headline)

            HStack(alignment: .top, spacing: 20) {
                // File 1
                VStack(alignment: .leading, spacing: 8) {
                    Text(file1.name).font(.body.bold())
                    Text("\(file1Fs)\(file1.path)")
                        .font(.caption).foregroundColor(.secondary)
                    Divider()
                    hashRow("MD5", hash1["md5"])
                    hashRow("SHA1", hash1["sha1"])
                }
                .frame(maxWidth: .infinity)

                // File 2
                VStack(alignment: .leading, spacing: 8) {
                    Text(file2.name).font(.body.bold())
                    Text("\(file2Fs)\(file2.path)")
                        .font(.caption).foregroundColor(.secondary)
                    Divider()
                    hashRow("MD5", hash2["md5"])
                    hashRow("SHA1", hash2["sha1"])
                }
                .frame(maxWidth: .infinity)
            }

            if !isLoading {
                Divider()
                let md5Match = hash1["md5"] != nil && hash1["md5"] == hash2["md5"]
                let sha1Match = hash1["sha1"] != nil && hash1["sha1"] == hash2["sha1"]

                HStack {
                    Image(systemName: md5Match && sha1Match ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(md5Match && sha1Match ? .green : .red)
                    Text(md5Match && sha1Match ? L10n.t("hash.match") : L10n.t("hash.mismatch"))
                        .font(.body.bold())
                }
            } else {
                ProgressView()
            }

            Button(L10n.t("close")) { dismiss() }
                .keyboardShortcut(.cancelAction)
        }
        .padding(20)
        .frame(width: 550)
        .task {
            async let h1 = RcloneAPI.hashFile(using: appState.client, fs: file1Fs, remote: file1.path)
            async let h2 = RcloneAPI.hashFile(using: appState.client, fs: file2Fs, remote: file2.path)
            hash1 = (try? await h1) ?? [:]
            hash2 = (try? await h2) ?? [:]
            isLoading = false
        }
    }

    private func hashRow(_ type: String, _ value: String?) -> some View {
        HStack {
            Text(type).font(.caption.bold()).frame(width: 40, alignment: .leading)
            Text(value ?? "\u{2014}")
                .font(.system(size: 10, design: .monospaced))
                .textSelection(.enabled)
                .lineLimit(1)
        }
    }
}
