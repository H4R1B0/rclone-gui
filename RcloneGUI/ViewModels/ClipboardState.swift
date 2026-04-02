import Foundation

@Observable
final class ClipboardState {
    enum Action {
        case copy
        case cut
    }

    private(set) var action: Action?
    private(set) var sourceFs: String = ""
    private(set) var sourcePath: String = ""
    private(set) var files: [(name: String, isDir: Bool)] = []

    var hasData: Bool { action != nil && !files.isEmpty }

    func copy(fs: String, path: String, selectedFiles: [(name: String, isDir: Bool)]) {
        self.action = .copy
        self.sourceFs = fs
        self.sourcePath = path
        self.files = selectedFiles
    }

    func cut(fs: String, path: String, selectedFiles: [(name: String, isDir: Bool)]) {
        self.action = .cut
        self.sourceFs = fs
        self.sourcePath = path
        self.files = selectedFiles
    }

    func clear() {
        action = nil
        sourceFs = ""
        sourcePath = ""
        files = []
    }
}
