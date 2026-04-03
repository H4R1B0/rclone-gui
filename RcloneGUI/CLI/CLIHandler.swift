import Foundation
import RcloneKit

enum CLIHandler {
    static func run(arguments: [String]) async {
        guard arguments.count >= 2 else {
            printUsage()
            return
        }

        let client = RcloneClient()
        client.initialize()
        defer { client.finalize() }

        let command = arguments[1]

        switch command {
        case "list", "ls":
            guard arguments.count >= 3 else {
                print("Usage: RcloneGUI list <remote:path>")
                return
            }
            let remotePath = arguments[2]
            let (fs, path) = parseRemotePath(remotePath)
            do {
                let files = try await RcloneAPI.listFiles(using: client, fs: fs, remote: path)
                for file in files {
                    let typeChar = file.isDir ? "d" : "-"
                    let size = file.isDir ? "-" : FormatUtils.formatBytes(file.size)
                    print("\(typeChar) \(size.padding(toLength: 12, withPad: " ", startingAt: 0)) \(file.name)")
                }
            } catch {
                print("Error: \(error.localizedDescription)")
            }

        case "remotes":
            do {
                let remotes = try await RcloneAPI.listRemotes(using: client)
                if remotes.isEmpty {
                    print("No remotes configured.")
                } else {
                    for remote in remotes {
                        print("  \(remote):")
                    }
                }
            } catch {
                print("Error: \(error.localizedDescription)")
            }

        case "copy":
            guard arguments.count >= 4 else {
                print("Usage: RcloneGUI copy <src> <dst>")
                return
            }
            let (srcFs, srcPath) = parseRemotePath(arguments[2])
            let (dstFs, dstPath) = parseRemotePath(arguments[3])
            do {
                let jobId = try await RcloneAPI.copyFileAsync(using: client, srcFs: srcFs, srcRemote: srcPath, dstFs: dstFs, dstRemote: dstPath)
                print("Copy started (job \(jobId))")
            } catch {
                print("Error: \(error.localizedDescription)")
            }

        case "move":
            guard arguments.count >= 4 else {
                print("Usage: RcloneGUI move <src> <dst>")
                return
            }
            let (srcFs, srcPath) = parseRemotePath(arguments[2])
            let (dstFs, dstPath) = parseRemotePath(arguments[3])
            do {
                let jobId = try await RcloneAPI.moveFileAsync(using: client, srcFs: srcFs, srcRemote: srcPath, dstFs: dstFs, dstRemote: dstPath)
                print("Move started (job \(jobId))")
            } catch {
                print("Error: \(error.localizedDescription)")
            }

        case "mkdir":
            guard arguments.count >= 3 else {
                print("Usage: RcloneGUI mkdir <remote:path>")
                return
            }
            let (fs, path) = parseRemotePath(arguments[2])
            do {
                try await RcloneAPI.mkdir(using: client, fs: fs, remote: path)
                print("Created: \(arguments[2])")
            } catch {
                print("Error: \(error.localizedDescription)")
            }

        case "version":
            print("\(AppConstants.appName) v\(AppConstants.appVersion) (librclone)")

        case "help", "--help", "-h":
            printUsage()

        default:
            print("Unknown command: \(command)")
            printUsage()
        }
    }

    private static func printUsage() {
        print("""
        RcloneGUI CLI

        Usage: RcloneGUI <command> [arguments]

        Commands:
          list <remote:path>      List files
          remotes                 List configured remotes
          copy <src> <dst>        Copy file/folder
          move <src> <dst>        Move file/folder
          mkdir <remote:path>     Create directory
          version                 Show version
          help                    Show this help

        Examples:
          RcloneGUI list gdrive:/Documents
          RcloneGUI copy /local/file.txt gdrive:/backup/
          RcloneGUI remotes
        """)
    }

    static func parseRemotePath(_ input: String) -> (fs: String, path: String) {
        if let colonIndex = input.firstIndex(of: ":") {
            let fs = String(input[input.startIndex...colonIndex])
            let path = String(input[input.index(after: colonIndex)...])
            return (fs, path)
        }
        // Local path
        return ("/", input)
    }
}
