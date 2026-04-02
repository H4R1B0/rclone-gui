import SwiftUI

struct SyncProfileSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    let remotes: [String]

    @State private var name = ""
    @State private var mode: SyncMode = .mirror
    @State private var sourceFs = "/"
    @State private var sourcePath = ""
    @State private var destFs = "/"
    @State private var destPath = ""
    @State private var filterText = ""
    @State private var error: String?

    var body: some View {
        VStack(spacing: 16) {
            Text(L10n.t("sync.createProfile"))
                .font(.headline)

            Form {
                TextField(L10n.t("properties.name"), text: $name)

                Picker(L10n.t("sync.mode"), selection: $mode) {
                    ForEach(SyncMode.allCases, id: \.self) { m in
                        Text(m.label).tag(m)
                    }
                }

                // Source
                Section(L10n.t("sync.source")) {
                    Picker(L10n.t("sync.remote"), selection: $sourceFs) {
                        Text(L10n.t("panel.local")).tag("/")
                        ForEach(remotes, id: \.self) { r in
                            Text(r).tag("\(r):")
                        }
                    }
                    TextField(L10n.t("properties.path"), text: $sourcePath)
                }

                // Destination
                Section(L10n.t("sync.destination")) {
                    Picker(L10n.t("sync.remote"), selection: $destFs) {
                        Text(L10n.t("panel.local")).tag("/")
                        ForEach(remotes, id: \.self) { r in
                            Text(r).tag("\(r):")
                        }
                    }
                    TextField(L10n.t("properties.path"), text: $destPath)
                }

                // Filters
                Section(L10n.t("sync.filters")) {
                    TextField(L10n.t("sync.filterHint"), text: $filterText)
                }
            }
            .formStyle(.grouped)

            // Mode description
            Text(mode.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            if let error = error {
                Text(error).foregroundColor(.red).font(.caption)
            }

            HStack {
                Button(L10n.t("cancel")) { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button(L10n.t("create")) { createProfile() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(20)
        .frame(width: 450, height: 550)
    }

    private func createProfile() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        let filters = filterText.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }

        let profile = SyncProfile(
            name: trimmedName,
            mode: mode,
            sourceFs: sourceFs,
            sourcePath: sourcePath,
            destFs: destFs,
            destPath: destPath,
            filterRules: filters
        )

        appState.sync.addProfile(profile)
        dismiss()
    }
}
