import SwiftUI

struct AccountSetupView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var remoteName: String = ""
    @State private var selectedType: String = "drive"
    @State private var errorMessage: String?
    @State private var isCreating: Bool = false

    private let providerTypes: [(id: String, name: String)] = [
        ("drive", "Google Drive"),
        ("onedrive", "Microsoft OneDrive"),
        ("dropbox", "Dropbox"),
        ("s3", "Amazon S3"),
        ("b2", "Backblaze B2"),
        ("box", "Box"),
        ("mega", "MEGA"),
        ("pcloud", "pCloud"),
        ("ftp", "FTP"),
        ("sftp", "SFTP"),
        ("webdav", "WebDAV"),
        ("local", "Local Disk"),
    ]

    var body: some View {
        VStack(spacing: 16) {
            Text("Add Account")
                .font(.headline)

            Form {
                TextField("Name", text: $remoteName)

                Picker("Type", selection: $selectedType) {
                    ForEach(providerTypes, id: \.id) { provider in
                        Text(provider.name).tag(provider.id)
                    }
                }
            }
            .formStyle(.grouped)

            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }

            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)

                Button("Create") { createRemote() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(remoteName.trimmingCharacters(in: .whitespaces).isEmpty || isCreating)
            }
        }
        .padding(20)
        .frame(width: 400)
    }

    private func createRemote() {
        let name = remoteName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }

        isCreating = true
        errorMessage = nil

        Task {
            do {
                try await appState.accounts.addRemote(name: name, type: selectedType, parameters: [:])
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isCreating = false
        }
    }
}
