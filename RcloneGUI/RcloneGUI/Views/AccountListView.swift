import SwiftUI

struct AccountListView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack {
            Text("Accounts")
                .font(.headline)
            Text("Coming soon")
                .foregroundColor(.secondary)
            Button("Close") { dismiss() }
        }
        .padding(20)
        .frame(width: 350, minHeight: 300)
    }
}
