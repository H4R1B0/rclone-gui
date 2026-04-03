import CoreSpotlight
import UniformTypeIdentifiers
import RcloneKit

class SpotlightIndexer {
    static let shared = SpotlightIndexer()
    private let domainID = "com.rclone-gui.files"

    /// Index files from a remote listing into Spotlight
    func indexFiles(remote: String, path: String, files: [FileItem]) {
        var items: [CSSearchableItem] = []

        for file in files.prefix(1000) {  // Limit to prevent overload
            let uniqueID = "\(remote)/\(file.path)"
            let contentType: UTType = file.isDir ? .folder : .item
            let attributes = CSSearchableItemAttributeSet(contentType: contentType)
            attributes.title = file.name
            attributes.contentDescription = "\(remote)\(file.path)"
            attributes.displayName = file.name
            attributes.path = file.path

            if !file.isDir {
                attributes.contentModificationDate = file.modTime
                attributes.fileSize = NSNumber(value: file.size)
            }

            let item = CSSearchableItem(
                uniqueIdentifier: uniqueID,
                domainIdentifier: domainID,
                attributeSet: attributes
            )
            item.expirationDate = Date().addingTimeInterval(86400 * 7)  // 7 days
            items.append(item)
        }

        CSSearchableIndex.default().indexSearchableItems(items) { error in
            if let error = error {
                print("[RcloneGUI] Spotlight indexing error: \(error.localizedDescription)")
            }
        }
    }

    /// Remove all indexed items
    func removeAllItems() {
        CSSearchableIndex.default().deleteSearchableItems(withDomainIdentifiers: [domainID]) { error in
            if let error = error {
                print("[RcloneGUI] Spotlight cleanup error: \(error.localizedDescription)")
            }
        }
    }

    /// Handle Spotlight result tap (CSSearchableItem continuation)
    func handleSpotlightActivity(_ activity: NSUserActivity) -> (remote: String, path: String)? {
        guard activity.activityType == CSSearchableItemActionType,
              let uniqueID = activity.userInfo?[CSSearchableItemActivityIdentifier] as? String
        else { return nil }

        // Parse "remote:/path" format
        if let colonIndex = uniqueID.firstIndex(of: "/") {
            let remote = String(uniqueID[uniqueID.startIndex..<colonIndex])
            let path = String(uniqueID[uniqueID.index(after: colonIndex)...])
            return (remote: remote.hasSuffix(":") ? remote : "\(remote):", path: path)
        }
        return nil
    }
}
