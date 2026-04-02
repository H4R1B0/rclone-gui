import SwiftUI
import RcloneKit

struct RemoteSelectorView: View {
    @Environment(AppState.self) private var appState
    @Bindable var viewModel: PanelViewModel

    var body: some View {
        Picker("Remote", selection: Binding(
            get: { viewModel.currentFs },
            set: { newFs in
                viewModel.currentFs = newFs
                Task { await viewModel.navigate(to: "") }
            }
        )) {
            Text("Local").tag("/")
            ForEach(appState.accounts.remotes) { remote in
                Text(remote.displayName).tag("\(remote.name):")
            }
        }
        .pickerStyle(.menu)
        .frame(width: 150)
    }
}
