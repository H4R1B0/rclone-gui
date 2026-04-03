import AppIntents
import RcloneKit

// MARK: - List Remotes Intent

struct ListRemotesIntent: AppIntent {
    static var title: LocalizedStringResource = "List Cloud Remotes"
    static var description = IntentDescription("List all configured cloud storage remotes")

    func perform() async throws -> some IntentResult & ReturnsValue<[String]> {
        let client = RcloneClient()
        client.initialize()
        defer { client.finalize() }
        let remotes = try await RcloneAPI.listRemotes(using: client)
        return .result(value: remotes)
    }
}

// MARK: - List Files Intent

struct ListFilesIntent: AppIntent {
    static var title: LocalizedStringResource = "List Files"
    static var description = IntentDescription("List files in a cloud storage path")

    @Parameter(title: "Remote (e.g., gdrive:)")
    var remote: String

    @Parameter(title: "Path", default: "")
    var path: String

    func perform() async throws -> some IntentResult & ReturnsValue<[String]> {
        let client = RcloneClient()
        client.initialize()
        defer { client.finalize() }
        let files = try await RcloneAPI.listFiles(using: client, fs: remote, remote: path)
        return .result(value: files.map { "\($0.isDir ? "📁" : "📄") \($0.name)" })
    }
}

// MARK: - Copy File Intent

struct CopyFileIntent: AppIntent {
    static var title: LocalizedStringResource = "Copy File to Cloud"
    static var description = IntentDescription("Copy a local file to cloud storage")

    @Parameter(title: "Local File Path")
    var localPath: String

    @Parameter(title: "Destination Remote (e.g., gdrive:)")
    var destRemote: String

    @Parameter(title: "Destination Path", default: "")
    var destPath: String

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let client = RcloneClient()
        client.initialize()
        defer { client.finalize() }
        let fileName = (localPath as NSString).lastPathComponent
        let dstRemote = destPath.isEmpty ? fileName : "\(destPath)/\(fileName)"
        let jobId = try await RcloneAPI.copyFileAsync(
            using: client,
            srcFs: "/", srcRemote: localPath,
            dstFs: destRemote, dstRemote: dstRemote
        )
        return .result(value: "Copy started (job \(jobId))")
    }
}

// MARK: - Create Folder Intent

struct CreateFolderIntent: AppIntent {
    static var title: LocalizedStringResource = "Create Folder"
    static var description = IntentDescription("Create a folder in cloud storage")

    @Parameter(title: "Remote (e.g., gdrive:)")
    var remote: String

    @Parameter(title: "Folder Path")
    var folderPath: String

    func perform() async throws -> some IntentResult {
        let client = RcloneClient()
        client.initialize()
        defer { client.finalize() }
        try await RcloneAPI.mkdir(using: client, fs: remote, remote: folderPath)
        return .result()
    }
}

// MARK: - Shortcuts Provider

struct RcloneGUIShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: ListRemotesIntent(),
            phrases: ["List cloud remotes in \(.applicationName)"],
            shortTitle: "List Remotes",
            systemImageName: "cloud"
        )
        AppShortcut(
            intent: CopyFileIntent(),
            phrases: ["Upload file with \(.applicationName)"],
            shortTitle: "Upload File",
            systemImageName: "arrow.up.doc"
        )
    }
}
