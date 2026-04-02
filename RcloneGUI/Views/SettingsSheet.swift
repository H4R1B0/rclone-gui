import SwiftUI

struct SettingsSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Settings")
                    .font(.title2.bold())
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Language
                    GroupBox("Language") {
                        HStack {
                            Text("App Language")
                            Spacer()
                            // Phase 2: locale switching
                            Text("English / 한국어")
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }

                    // Phase 2: Performance settings
                    GroupBox("Performance") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Transfer settings will be available in a future update.")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                        .padding(.vertical, 4)
                    }

                    // Phase 2: Security settings
                    GroupBox("Security") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("App lock settings will be available in a future update.")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding()
            }

            Divider()

            HStack {
                Spacer()
                Button("Close") { dismiss() }
                    .keyboardShortcut(.cancelAction)
            }
            .padding()
        }
        .frame(width: 500, height: 450)
    }
}
