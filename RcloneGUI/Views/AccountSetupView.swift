import SwiftUI
import UniformTypeIdentifiers
import RcloneKit

enum AccountStep {
    case list
    case pickProvider
    case create(RcloneProvider)
    case edit(Remote)
}

struct AccountSetupView: View {
    @Environment(AppState.self) private var appState
    @State private var step: AccountStep = .list
    @State private var error: String?
    @State private var showCryptSetup = false
    @State private var showUnionSetup = false
    @State private var providerSearch = ""

    var body: some View {
        VStack(spacing: 0) {
            switch step {
            case .list:
                remoteListView
            case .pickProvider:
                providerPickerView
            case .create(let provider):
                createRemoteView(provider: provider)
            case .edit(let remote):
                editRemoteView(remote: remote)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task {
            if appState.accounts.providers.isEmpty {
                await appState.accounts.loadProviders()
            }
        }
    }

    // MARK: - Remote List

    private var remoteListView: some View {
        VStack(spacing: 0) {
            HStack {
                Text(L10n.t("account.title"))
                    .font(.title2.bold())
                Spacer()
                Button(action: { showUnionSetup = true }) {
                    Label(L10n.t("union.title"), systemImage: "externaldrive.badge.plus")
                }
                Button(action: { showCryptSetup = true }) {
                    Label(L10n.t("crypt.title"), systemImage: "lock.shield")
                }
                Button(action: exportConfig) {
                    Image(systemName: "square.and.arrow.up")
                }
                .buttonStyle(.borderless)
                .help(L10n.t("account.export"))

                Button(action: importConfig) {
                    Image(systemName: "square.and.arrow.down")
                }
                .buttonStyle(.borderless)
                .help(L10n.t("account.import"))

                Button(action: { step = .pickProvider }) {
                    Label(L10n.t("account.add"), systemImage: "plus")
                }
            }
            .padding()
            .sheet(isPresented: $showCryptSetup) { CryptSetupSheet() }
            .sheet(isPresented: $showUnionSetup) { UnionSetupSheet() }

            Divider()

            if appState.accounts.remotes.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "cloud")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text(L10n.t("account.noAccounts"))
                        .foregroundColor(.secondary)
                    Button(L10n.t("account.add")) { step = .pickProvider }
                }
                .frame(maxHeight: .infinity)
            } else {
                List {
                    ForEach(appState.accounts.remotes) { remote in
                        remoteCard(remote)
                    }
                }
                .listStyle(.inset)
            }
        }
    }

    private func remoteCard(_ remote: Remote) -> some View {
        HStack {
            Image(systemName: "cloud.fill")
                .foregroundColor(.accentColor)
                .font(.system(size: 20))

            VStack(alignment: .leading) {
                Text(remote.displayName)
                    .font(.body)
                Text(remote.type)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: { step = .edit(remote) }) {
                Image(systemName: "pencil")
            }
            .buttonStyle(.borderless)

            Button(role: .destructive, action: {
                Task { try? await appState.accounts.deleteRemote(name: remote.name) }
            }) {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Import / Export

    private func exportConfig() {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "rclone.conf"
        panel.allowedContentTypes = [.plainText]
        panel.begin { result in
            guard result == .OK, let url = panel.url else { return }
            Task {
                do {
                    let result = try await appState.client.call("config/dump", params: [:])
                    let data = try JSONSerialization.data(withJSONObject: result, options: .prettyPrinted)
                    try data.write(to: url)
                } catch {}
            }
        }
    }

    private func importConfig() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.plainText, .json]
        panel.begin { result in
            guard result == .OK, let url = panel.url else { return }
            Task {
                if let data = try? Data(contentsOf: url),
                   let dict = try? JSONSerialization.jsonObject(with: data) as? [String: [String: String]] {
                    for (name, params) in dict {
                        if let type = params["type"] {
                            var cleanParams = params
                            cleanParams.removeValue(forKey: "type")
                            try? await appState.accounts.createRemote(name: name, type: type, parameters: cleanParams)
                        }
                    }
                    await appState.accounts.loadRemotes()
                }
            }
        }
    }

    // MARK: - Provider Picker

    private var providerPickerView: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: { step = .list }) {
                    Image(systemName: "chevron.left")
                    Text(L10n.t("back"))
                }
                .buttonStyle(.plain)
                Spacer()
                Text(L10n.t("account.chooseProvider")).font(.headline)
                Spacer()
            }
            .padding()

            Divider()

            TextField(L10n.t("account.searchProvider"), text: $providerSearch)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, 16)
                .padding(.top, 8)

            ScrollView {
                LazyVStack(spacing: 2) {
                    let filteredProviders = appState.accounts.providers.filter { provider in
                        providerSearch.isEmpty ||
                        provider.name.localizedCaseInsensitiveContains(providerSearch) ||
                        provider.description.localizedCaseInsensitiveContains(providerSearch) ||
                        provider.prefix.localizedCaseInsensitiveContains(providerSearch)
                    }
                    ForEach(filteredProviders) { provider in
                        Button(action: { step = .create(provider) }) {
                            HStack {
                                Image(systemName: "cloud")
                                    .frame(width: 24)
                                VStack(alignment: .leading) {
                                    Text(provider.name)
                                        .font(.body)
                                    Text(provider.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Create Remote

    private func createRemoteView(provider: RcloneProvider) -> some View {
        RemoteFormView(
            title: "Add \(provider.name)",
            provider: provider,
            initialName: "",
            initialParams: [:],
            onBack: { step = .pickProvider },
            onSave: { name, params in
                try await appState.accounts.createRemote(name: name, type: provider.prefix, parameters: params)
                step = .list
            }
        )
    }

    // MARK: - Edit Remote

    private func editRemoteView(remote: Remote) -> some View {
        let provider = appState.accounts.providers.first { $0.prefix == remote.type }

        return Group {
            if let provider = provider {
                RemoteFormView(
                    title: "Edit \(remote.displayName)",
                    provider: provider,
                    initialName: remote.name,
                    initialParams: [:],
                    loadExisting: remote.name,
                    onBack: { step = .list },
                    onSave: { name, params in
                        try await appState.accounts.updateRemote(
                            oldName: remote.name, newName: name,
                            type: provider.prefix, parameters: params
                        )
                        step = .list
                    }
                )
            } else {
                VStack {
                    Text("\(L10n.t("account.providerNotFound")): \(remote.type)")
                        .foregroundColor(.red)
                    Button(L10n.t("back")) { step = .list }
                }
            }
        }
    }
}

// MARK: - Remote Form (shared by create + edit)

struct RemoteFormView: View {
    @Environment(AppState.self) private var appState
    let title: String
    let provider: RcloneProvider
    let initialName: String
    let initialParams: [String: String]
    var loadExisting: String? = nil
    let onBack: () -> Void
    let onSave: (String, [String: String]) async throws -> Void

    @State private var remoteName: String = ""
    @State private var params: [String: String] = [:]
    @State private var showAdvanced = false
    @State private var saving = false
    @State private var error: String?

    private var visibleOptions: [ProviderOption] {
        provider.options.filter { opt in
            guard opt.isVisible else { return false }
            if opt.advanced && !showAdvanced { return false }
            return true
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                    Text(L10n.t("back"))
                }
                .buttonStyle(.plain)
                Spacer()
                Text(title).font(.headline)
                Spacer()
            }
            .padding()

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    // Name field
                    VStack(alignment: .leading, spacing: 4) {
                        Text(L10n.t("properties.name")).font(.caption.bold())
                        TextField(L10n.t("account.remoteName"), text: $remoteName)
                            .textFieldStyle(.roundedBorder)
                    }

                    Divider()

                    // Provider fields
                    ForEach(visibleOptions, id: \.name) { option in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(option.name)
                                    .font(.caption.bold())
                                if option.required {
                                    Text("*").foregroundColor(.red)
                                }
                            }

                            if option.help.count < 100 {
                                Text(option.help)
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                            }

                            if option.isPassword {
                                SecureField(option.name, text: binding(for: option))
                                    .textFieldStyle(.roundedBorder)
                            } else {
                                TextField(option.name, text: binding(for: option))
                                    .textFieldStyle(.roundedBorder)
                            }
                        }
                    }

                    // Advanced toggle
                    if provider.options.contains(where: { $0.advanced && $0.isVisible }) {
                        Toggle(L10n.t("account.showAdvanced"), isOn: $showAdvanced)
                            .font(.caption)
                    }

                    if let error = error {
                        Text(error).foregroundColor(.red).font(.caption)
                    }

                    // Save button
                    HStack {
                        Spacer()
                        Button(saving ? L10n.t("saving") : L10n.t("connect")) {
                            save()
                        }
                        .disabled(remoteName.trimmingCharacters(in: .whitespaces).isEmpty || saving)
                        .keyboardShortcut(.defaultAction)
                    }
                }
                .padding()
            }
        }
        .onAppear {
            remoteName = initialName
            params = initialParams
        }
        .task {
            if let existing = loadExisting {
                do {
                    params = try await appState.accounts.getRemoteConfig(name: existing)
                } catch {}
            }
        }
    }

    private func binding(for option: ProviderOption) -> Binding<String> {
        Binding(
            get: { params[option.name] ?? option.defaultValue },
            set: { params[option.name] = $0 }
        )
    }

    private func save() {
        saving = true
        error = nil
        let name = remoteName.trimmingCharacters(in: .whitespaces)
        Task {
            do {
                try await onSave(name, params)
            } catch {
                self.error = error.localizedDescription
            }
            saving = false
        }
    }
}
