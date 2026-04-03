import SwiftUI

enum ProviderIcon {
    @ViewBuilder
    static func icon(for type: String, size: CGFloat = 16) -> some View {
        ProviderIconView(type: type, size: size)
    }

    static func iconInfo(for type: String) -> (symbol: String, color: Color) {
        switch type.lowercased() {
        case "drive": return ("triangle.fill", .blue)
        case "onedrive": return ("cloud.fill", .cyan)
        case "dropbox": return ("shippingbox.fill", .blue)
        case "s3": return ("cube.fill", .orange)
        case "b2": return ("flame.fill", .red)
        case "box": return ("archivebox.fill", .blue)
        case "mega": return ("lock.shield.fill", .red)
        case "pcloud": return ("cloud.fill", .green)
        case "ftp": return ("network", .gray)
        case "sftp": return ("lock.shield", .green)
        case "webdav": return ("globe", .blue)
        case "swift", "hubic": return ("cloud.fill", .indigo)
        case "azureblob": return ("cloud.fill", .cyan)
        case "gcs": return ("cloud.fill", .red)
        case "crypt": return ("lock.fill", .purple)
        case "local": return ("internaldrive", .gray)
        case "union": return ("link.circle.fill", .orange)
        case "alias": return ("arrow.triangle.branch", .gray)
        default: return ("cloud", .secondary)
        }
    }
}

/// Shows real favicon if cached, SF Symbol fallback otherwise
struct ProviderIconView: View {
    let type: String
    let size: CGFloat

    @State private var image: NSImage?

    var body: some View {
        Group {
            if let img = image {
                Image(nsImage: img)
                    .resizable()
                    .interpolation(.high)
                    .frame(width: size, height: size)
            } else {
                let info = ProviderIcon.iconInfo(for: type)
                Image(systemName: info.symbol)
                    .foregroundColor(info.color)
            }
        }
        .onAppear { image = ProviderIconLoader.shared.image(for: type) }
        .onChange(of: type) { image = ProviderIconLoader.shared.image(for: type) }
    }
}
