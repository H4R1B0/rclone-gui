import SwiftUI

enum ProviderIcon {
    @ViewBuilder
    static func icon(for type: String) -> some View {
        let info = iconInfo(for: type)
        Image(systemName: info.symbol)
            .foregroundColor(info.color)
    }

    static func iconInfo(for type: String) -> (symbol: String, color: Color) {
        switch type.lowercased() {
        case "drive": return ("triangle.fill", .blue)          // Google Drive
        case "onedrive": return ("cloud.fill", .cyan)          // OneDrive
        case "dropbox": return ("shippingbox.fill", .blue)     // Dropbox
        case "s3": return ("cube.fill", .orange)               // AWS S3
        case "b2": return ("flame.fill", .red)                 // Backblaze B2
        case "box": return ("archivebox.fill", .blue)          // Box
        case "mega": return ("lock.shield.fill", .red)         // MEGA
        case "pcloud": return ("cloud.fill", .green)           // pCloud
        case "ftp": return ("network", .gray)                  // FTP
        case "sftp": return ("lock.shield", .green)            // SFTP
        case "webdav": return ("globe", .blue)                 // WebDAV
        case "swift", "hubic": return ("cloud.fill", .indigo)  // OpenStack Swift
        case "azureblob": return ("cloud.fill", .cyan)         // Azure
        case "gcs": return ("cloud.fill", .red)                // Google Cloud Storage
        case "crypt": return ("lock.fill", .purple)            // Crypt
        case "local": return ("internaldrive", .gray)          // Local
        case "union": return ("link.circle.fill", .orange)     // Union
        case "alias": return ("arrow.triangle.branch", .gray)  // Alias
        default: return ("cloud", .secondary)                   // Unknown
        }
    }
}
