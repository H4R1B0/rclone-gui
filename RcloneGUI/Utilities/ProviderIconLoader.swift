import SwiftUI
import AppKit

/// Loads provider icons from the app bundle (Resources/ProviderIcons/).
/// Falls back to SF Symbol icons when unavailable.
@Observable
final class ProviderIconLoader {
    static let shared = ProviderIconLoader()

    private var cache: [String: NSImage] = [:]

    private init() {}

    func image(for type: String) -> NSImage? {
        let key = type.lowercased()
        if let cached = cache[key] { return cached }

        // Load from app bundle
        if let url = Bundle.main.url(forResource: key, withExtension: "png", subdirectory: "ProviderIcons"),
           let img = NSImage(contentsOf: url) {
            cache[key] = img
            return img
        }

        return nil
    }
}
