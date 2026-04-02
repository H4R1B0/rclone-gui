import Foundation
import RcloneKit
import FileBrowser

@Observable
public final class PanelViewModel {
    var currentFs: String = "/"
    var currentPath: String = ""
    var files: [FileItem] = []
    var selectedFileIDs: Set<String> = []
    var sortOrder: SortOrder = .name
    var sortAscending: Bool = true
    var isLoading: Bool = false
    var error: String?

    let fileOps: FileOperations

    init(client: RcloneClientProtocol) {
        self.fileOps = FileOperations(client: client)
    }

    var displayPath: String {
        currentFs == "/" ? "/\(currentPath)" : "\(currentFs)/\(currentPath)"
    }

    var selectedFiles: [FileItem] {
        files.filter { selectedFileIDs.contains($0.id) }
    }

    @MainActor
    func navigate(to path: String) async {
        isLoading = true
        error = nil
        do {
            let rawFiles = try await fileOps.list(fs: currentFs, path: path)
            files = sortOrder.sorted(rawFiles, ascending: sortAscending)
            currentPath = path
            selectedFileIDs = []
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    @MainActor
    func refresh() async {
        await navigate(to: currentPath)
    }

    @MainActor
    func navigateUp() async {
        let parent = (currentPath as NSString).deletingLastPathComponent
        await navigate(to: parent == "." ? "" : parent)
    }

    @MainActor
    func navigateInto(_ item: FileItem) async {
        guard item.isDir else { return }
        await navigate(to: item.path)
    }

    func resort() {
        files = sortOrder.sorted(files, ascending: sortAscending)
    }

    @MainActor
    func mkdir(name: String) async throws {
        let path = currentPath.isEmpty ? name : "\(currentPath)/\(name)"
        try await fileOps.mkdir(fs: currentFs, path: path)
        await refresh()
    }

    @MainActor
    func deleteSelected() async throws {
        for file in selectedFiles {
            try await fileOps.delete(fs: currentFs, remote: file.path, isDir: file.isDir)
        }
        await refresh()
    }

    @MainActor
    func rename(file: FileItem, to newName: String) async throws {
        let parentPath = (file.path as NSString).deletingLastPathComponent
        let parent = parentPath == "." ? "" : parentPath
        try await fileOps.rename(fs: currentFs, path: parent, from: file.name, to: newName)
        await refresh()
    }
}
