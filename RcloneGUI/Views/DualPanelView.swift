import SwiftUI

struct DualPanelView: View {
    @Environment(AppState.self) private var appState
    @State private var splitFraction: CGFloat = 0.5  // 0.0-1.0
    @State private var isDragging = false

    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 0) {
                // Left panel
                PanelView(viewModel: appState.panels, side: .left)
                    .frame(width: geo.size.width * splitFraction)

                // Draggable divider
                Rectangle()
                    .fill(Color(nsColor: .separatorColor))
                    .frame(width: 1)
                    .overlay(
                        Rectangle()
                            .fill(Color.clear)
                            .frame(width: 8)
                            .contentShape(Rectangle())
                            .cursor(.resizeLeftRight)
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        isDragging = true
                                        let fraction = (geo.size.width * splitFraction + value.translation.width) / geo.size.width
                                        splitFraction = min(max(fraction, 0.2), 0.8)
                                    }
                                    .onEnded { _ in
                                        isDragging = false
                                    }
                            )
                    )

                // Right panel
                PanelView(viewModel: appState.panels, side: .right)
                    .frame(maxWidth: .infinity)
            }
        }
    }
}

// MARK: - Cursor modifier for resize

extension View {
    func cursor(_ cursor: NSCursor) -> some View {
        self.onHover { inside in
            if inside {
                cursor.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}
