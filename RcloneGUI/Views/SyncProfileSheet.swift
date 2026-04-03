import SwiftUI

struct SyncRule: Identifiable {
    let id = UUID()
    var type: RuleType = .exclude
    var pattern: String = ""

    enum RuleType: String, CaseIterable {
        case exclude = "exclude"
        case include = "include"
        case minSize = "min-size"
        case maxSize = "max-size"
        case minAge = "min-age"
        case maxAge = "max-age"

        var label: String {
            switch self {
            case .exclude: return L10n.t("sync.rule.exclude")
            case .include: return L10n.t("sync.rule.include")
            case .minSize: return L10n.t("sync.rule.minSize")
            case .maxSize: return L10n.t("sync.rule.maxSize")
            case .minAge: return L10n.t("sync.rule.minAge")
            case .maxAge: return L10n.t("sync.rule.maxAge")
            }
        }
    }
}

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
    @State private var rules: [SyncRule] = []
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

                // Sync Rules
                Section(L10n.t("sync.rules")) {
                    ForEach($rules) { $rule in
                        HStack(spacing: 4) {
                            Picker("", selection: $rule.type) {
                                ForEach(SyncRule.RuleType.allCases, id: \.self) { t in
                                    Text(t.label).tag(t)
                                }
                            }
                            .frame(width: 120)

                            TextField(L10n.t("sync.rule.pattern"), text: $rule.pattern)
                                .textFieldStyle(.roundedBorder)

                            Button(action: { rules.removeAll { $0.id == rule.id } }) {
                                Image(systemName: "minus.circle").foregroundColor(.red)
                            }
                            .buttonStyle(.plain)
                        }
                        .font(.system(size: 11))
                    }

                    Button(action: { rules.append(SyncRule()) }) {
                        Label(L10n.t("sync.rule.add"), systemImage: "plus")
                    }
                    .controlSize(.small)

                    Text(L10n.t("sync.rule.help"))
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
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

        let filters = rules.compactMap { rule -> String? in
            guard !rule.pattern.isEmpty else { return nil }
            return "\(rule.type.rawValue) \(rule.pattern)"
        }

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
