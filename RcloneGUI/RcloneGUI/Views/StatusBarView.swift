import SwiftUI

struct StatusBarView: View {
    var body: some View {
        HStack {
            Text("Ready")
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}
