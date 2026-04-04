import SwiftUI

struct MountView: View {
    @Environment(AppState.self) private var appState
    @State private var showMount = false
    @State private var selectedRemote = ""
    @State private var mountPath = ""
    @State private var error: String?

    private var mountVM: MountViewModel { appState.mount }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(L10n.t("mount.title")).font(.headline)
                Spacer()
                Button(action: { showMount = true }) {
                    Label(L10n.t("mount.new"), systemImage: "plus")
                }
            }
            .padding()

            Divider()

            if mountVM.isLoading {
                MountListSkeleton()
            } else if let error = mountVM.error, error.contains("couldn't find method") || error.contains("status 404") {
                // macFUSE not installed
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 36))
                        .foregroundColor(.orange)
                    Text(L10n.t("mount.fuseRequired"))
                        .font(.headline)
                    Text(L10n.t("mount.fuseDescription"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 350)
                    Link(L10n.t("mount.fuseDownload"), destination: URL(string: "https://osxfuse.github.io/")!)
                        .font(.system(size: 12))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = mountVM.error {
                ErrorRetryView(
                    message: error,
                    onRetry: { Task { await mountVM.loadMounts() } }
                )
            } else if mountVM.mounts.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "externaldrive.connected.to.line.below")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                    Text(L10n.t("mount.noMounts"))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(mountVM.mounts) { mount in
                        HStack {
                            Image(systemName: "externaldrive.fill")
                                .foregroundColor(.accentColor)
                            VStack(alignment: .leading) {
                                Text(mount.fs).font(.body)
                                Text(mount.mountPoint)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Button(L10n.t("mount.unmount")) {
                                Task { try? await mountVM.unmount(mountPoint: mount.mountPoint) }
                            }
                            .controlSize(.small)
                        }
                    }
                }
                .listStyle(.inset)
            }
        }
        .task { await mountVM.loadMounts() }
        .sheet(isPresented: $showMount) {
            VStack(spacing: 16) {
                Text(L10n.t("mount.new")).font(.headline)

                Form {
                    Picker(L10n.t("sync.remote"), selection: $selectedRemote) {
                        Text("--").tag("")
                        ForEach(appState.accounts.remotes) { remote in
                            Text(remote.displayName).tag("\(remote.name):")
                        }
                    }

                    TextField(L10n.t("mount.mountPoint"), text: $mountPath)
                        .help(L10n.t("mount.mountPointHint"))
                }
                .formStyle(.grouped)

                if let error = error {
                    Text(error).foregroundColor(.red).font(.caption)
                }

                HStack {
                    Button(L10n.t("cancel")) { showMount = false }
                        .keyboardShortcut(.cancelAction)
                    Button(L10n.t("mount.mount")) {
                        Task {
                            do {
                                try await mountVM.mount(fs: selectedRemote, mountPoint: mountPath)
                                showMount = false
                            } catch {
                                self.error = error.localizedDescription
                            }
                        }
                    }
                    .keyboardShortcut(.defaultAction)
                    .disabled(selectedRemote.isEmpty || mountPath.isEmpty)
                }
            }
            .padding(20)
            .frame(width: 400)
        }
    }
}
