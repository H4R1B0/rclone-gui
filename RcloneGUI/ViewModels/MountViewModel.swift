import Foundation
import RcloneKit

struct MountPoint: Identifiable {
    let id = UUID()
    let fs: String
    let mountPoint: String
}

@Observable
final class MountViewModel {
    var mounts: [MountPoint] = []
    var isLoading: Bool = false
    var error: String?

    private let client: RcloneClientProtocol

    init(client: RcloneClientProtocol) {
        self.client = client
    }

    @MainActor
    func loadMounts() async {
        isLoading = true
        do {
            let list = try await RcloneAPI.listMounts(using: client)
            mounts = list.compactMap { dict in
                guard let fs = dict["Fs"] as? String,
                      let mp = dict["MountPoint"] as? String
                else { return nil }
                return MountPoint(fs: fs, mountPoint: mp)
            }
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    @MainActor
    func mount(fs: String, mountPoint: String) async throws {
        try await RcloneAPI.mount(using: client, fs: fs, mountPoint: mountPoint)
        await loadMounts()
    }

    @MainActor
    func unmount(mountPoint: String) async throws {
        try await RcloneAPI.unmount(using: client, mountPoint: mountPoint)
        await loadMounts()
    }
}
