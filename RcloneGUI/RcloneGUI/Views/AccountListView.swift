import SwiftUI
import RcloneKit

struct AccountListView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var showingAddAccount = false
    @State private var remoteToDelete: Remote?

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Accounts")
                    .font(.headline)
                Spacer()
                Button(action: { showingAddAccount = true }) {
                    Image(systemName: "plus")
                }
            }
            .padding()

            Divider()

            if appState.accounts.isLoading {
                ProgressView()
                    .frame(maxHeight: .infinity)
            } else if appState.accounts.remotes.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "cloud")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text("No accounts configured")
                        .foregroundColor(.secondary)
                    Button("Add Account") { showingAddAccount = true }
                }
                .frame(maxHeight: .infinity)
            } else {
                List {
                    ForEach(appState.accounts.remotes) { remote in
                        HStack {
                            Image(systemName: "cloud.fill")
                                .foregroundColor(.accentColor)
                            VStack(alignment: .leading) {
                                Text(remote.displayName)
                                    .font(.body)
                                Text(remote.type)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .contextMenu {
                            Button("Delete", role: .destructive) {
                                remoteToDelete = remote
                            }
                        }
                    }
                }
                .listStyle(.inset)
            }
        }
        .frame(width: 350, height: 400)
        .sheet(isPresented: $showingAddAccount) {
            AccountSetupView()
        }
        .alert("Delete Account?", isPresented: Binding(
            get: { remoteToDelete != nil },
            set: { if !$0 { remoteToDelete = nil } }
        )) {
            Button("Cancel", role: .cancel) { remoteToDelete = nil }
            Button("Delete", role: .destructive) {
                if let remote = remoteToDelete {
                    Task {
                        try? await appState.accounts.deleteRemote(name: remote.name)
                        remoteToDelete = nil
                    }
                }
            }
        } message: {
            if let remote = remoteToDelete {
                Text("Are you sure you want to delete \"\(remote.displayName)\"?")
            }
        }
    }
}
