import Foundation
import RcloneKit

enum URLSchemeHandler {
    /// Parse rclonegui://command?params URL
    /// Examples:
    ///   rclonegui://open?remote=gdrive&path=/Documents
    ///   rclonegui://mount?remote=gdrive
    ///   rclonegui://sync?profile=MyBackup
    static func handle(_ url: URL, appState: AppState) {
        guard url.scheme == "rclonegui" else { return }
        let command = url.host ?? ""
        let params = parseQuery(url.query)

        Task { @MainActor in
            switch command {
            case "open":
                if let remote = params["remote"], let path = params["path"] {
                    let fs = remote.hasSuffix(":") ? remote : "\(remote):"
                    await appState.panels.navigateTo(side: .left, remote: fs, path: path)
                }

            case "mount":
                if let remote = params["remote"] {
                    let fs = remote.hasSuffix(":") ? remote : "\(remote):"
                    try? await appState.mount.mount(fs: fs, mountPoint: params["path"] ?? "/tmp/\(remote)")
                }

            case "sync":
                if let profileName = params["profile"],
                   let profile = appState.sync.profiles.first(where: { $0.name == profileName }) {
                    await appState.sync.runSync(profile: profile)
                }

            case "upload":
                if let remote = params["remote"], let file = params["file"] {
                    let fs = remote.hasSuffix(":") ? remote : "\(remote):"
                    let dstPath = params["path"] ?? ""
                    let fileName = (file as NSString).lastPathComponent
                    let dstRemote = dstPath.isEmpty ? fileName : "\(dstPath)/\(fileName)"
                    _ = try? await RcloneAPI.copyFileAsync(
                        using: appState.client,
                        srcFs: "/", srcRemote: file,
                        dstFs: fs, dstRemote: dstRemote
                    )
                }

            default:
                print("[RcloneGUI] Unknown URL scheme command: \(command)")
            }
        }
    }

    private static func parseQuery(_ query: String?) -> [String: String] {
        guard let query = query else { return [:] }
        var params: [String: String] = [:]
        for pair in query.split(separator: "&") {
            let parts = pair.split(separator: "=", maxSplits: 1)
            if parts.count == 2 {
                let key = String(parts[0]).removingPercentEncoding ?? String(parts[0])
                let value = String(parts[1]).removingPercentEncoding ?? String(parts[1])
                params[key] = value
            }
        }
        return params
    }
}
