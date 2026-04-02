import SwiftUI

struct DualPanelView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        HSplitView {
            PanelView(viewModel: appState.leftPanel, side: .left)
                .frame(minWidth: 300)

            PanelView(viewModel: appState.rightPanel, side: .right)
                .frame(minWidth: 300)
        }
    }
}

enum PanelSide {
    case left, right
}
