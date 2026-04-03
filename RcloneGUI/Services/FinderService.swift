import AppKit
import RcloneKit

class FinderService: NSObject {
    static let shared = FinderService()

    func registerServices() {
        NSApp.servicesProvider = self
        NSUpdateDynamicServices()
    }

    /// Called when user selects "Upload to RcloneGUI" from Finder Services menu
    @objc func uploadToCloud(_ pboard: NSPasteboard, userData: String, error: AutoreleasingUnsafeMutablePointer<NSString>) {
        guard let urls = pboard.readObjects(forClasses: [NSURL.self]) as? [URL] else { return }

        // Post notification for the app to handle
        NotificationCenter.default.post(
            name: .finderUploadRequested,
            object: urls
        )
    }
}

extension Notification.Name {
    static let finderUploadRequested = Notification.Name("finderUploadRequested")
}
