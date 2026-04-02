import SwiftUI

struct CryptSetupSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var baseRemote = ""
    @State private var basePath = ""
    @State private var password = ""
    @State private var password2 = ""
    @State private var filenameEncryption = "standard"  // standard, off, obfuscate
    @State private var directoryNameEncryption = true
    @State private var error: String?
    @State private var saving = false

    var body: some View {
        VStack(spacing: 16) {
            Text(L10n.t("crypt.title")).font(.headline)

            Form {
                TextField(L10n.t("crypt.name"), text: $name)

                Section(L10n.t("crypt.baseRemote")) {
                    Picker(L10n.t("sync.remote"), selection: $baseRemote) {
                        Text("--").tag("")
                        ForEach(appState.accounts.remotes) { remote in
                            Text(remote.displayName).tag("\(remote.name):")
                        }
                    }
                    TextField(L10n.t("properties.path"), text: $basePath)
                }

                Section(L10n.t("crypt.passwords")) {
                    SecureField(L10n.t("crypt.password"), text: $password)
                    SecureField(L10n.t("crypt.password2"), text: $password2)
                        .help(L10n.t("crypt.password2Help"))
                }

                Section(L10n.t("crypt.options")) {
                    Picker(L10n.t("crypt.filenameEnc"), selection: $filenameEncryption) {
                        Text("Standard").tag("standard")
                        Text(L10n.t("crypt.off")).tag("off")
                        Text("Obfuscate").tag("obfuscate")
                    }
                    Toggle(L10n.t("crypt.dirNameEnc"), isOn: $directoryNameEncryption)
                        .font(.system(size: 12))
                }
            }
            .formStyle(.grouped)

            if let error = error {
                Text(error).foregroundColor(.red).font(.caption)
            }

            HStack {
                Button(L10n.t("cancel")) { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button(saving ? L10n.t("saving") : L10n.t("create")) { create() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(name.isEmpty || baseRemote.isEmpty || password.isEmpty || saving)
            }
        }
        .padding(20)
        .frame(width: 450, height: 500)
    }

    private func create() {
        saving = true
        error = nil
        let remotePath = basePath.isEmpty ? baseRemote : "\(baseRemote)\(basePath)"
        Task {
            do {
                try await appState.accounts.createRemote(
                    name: name.trimmingCharacters(in: .whitespaces),
                    type: "crypt",
                    parameters: [
                        "remote": remotePath,
                        "password": password,
                        "password2": password2,
                        "filename_encryption": filenameEncryption,
                        "directory_name_encryption": directoryNameEncryption ? "true" : "false"
                    ]
                )
                dismiss()
            } catch {
                self.error = error.localizedDescription
            }
            saving = false
        }
    }
}
