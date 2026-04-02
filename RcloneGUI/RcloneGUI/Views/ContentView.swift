import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState
    @State private var showingAccounts = false

    var body: some View {
        VStack(spacing: 0) {
            DualPanelView()

            Divider()

            TransferPanelView()
                .frame(minHeight: 100, maxHeight: 300)

            StatusBarView()
        }
        .frame(minWidth: 900, minHeight: 600)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingAccounts.toggle() }) {
                    Image(systemName: "person.crop.circle")
                }
                .help("Manage Accounts")
            }
        }
        .sheet(isPresented: $showingAccounts) {
            AccountListView()
        }
    }
}
