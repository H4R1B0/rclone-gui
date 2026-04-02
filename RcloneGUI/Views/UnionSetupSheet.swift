import SwiftUI

struct UnionSetupSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var selectedRemotes: Set<String> = []
    @State private var error: String?
    @State private var saving = false

    var body: some View {
        VStack(spacing: 16) {
            Text(L10n.t("union.title")).font(.headline)

            TextField(L10n.t("union.name"), text: $name)
                .textFieldStyle(.roundedBorder)

            Text(L10n.t("union.selectRemotes"))
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            List {
                ForEach(appState.accounts.remotes) { remote in
                    HStack {
                        Image(systemName: selectedRemotes.contains(remote.name) ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(selectedRemotes.contains(remote.name) ? .accentColor : .secondary)
                        Text(remote.displayName)
                        Spacer()
                        Text(remote.type).font(.caption).foregroundColor(.secondary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if selectedRemotes.contains(remote.name) {
                            selectedRemotes.remove(remote.name)
                        } else {
                            selectedRemotes.insert(remote.name)
                        }
                    }
                }
            }
            .listStyle(.inset)
            .frame(height: 200)

            if let error = error {
                Text(error).foregroundColor(.red).font(.caption)
            }

            HStack {
                Button(L10n.t("cancel")) { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button(saving ? L10n.t("saving") : L10n.t("create")) {
                    saving = true
                    let upstreams = selectedRemotes.map { "\($0):" }.joined(separator: " ")
                    Task {
                        do {
                            try await appState.accounts.createRemote(
                                name: name.trimmingCharacters(in: .whitespaces),
                                type: "union",
                                parameters: ["upstreams": upstreams]
                            )
                            dismiss()
                        } catch {
                            self.error = error.localizedDescription
                        }
                        saving = false
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(name.isEmpty || selectedRemotes.count < 2 || saving)
            }
        }
        .padding(20)
        .frame(width: 400, height: 450)
    }
}
