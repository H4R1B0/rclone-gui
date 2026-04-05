import SwiftUI

struct ExplorerView: View {
    @Environment(AppState.self) private var appState
    @State private var splitFraction: CGFloat = 0.5
    @State private var isDraggingDivider = false

    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { geo in
                HStack(spacing: 0) {
                    FilePane(side: .left)
                        .frame(width: geo.size.width * splitFraction)

                    Divider()
                        .overlay(
                            Rectangle()
                                .fill(isDraggingDivider ? Color.accentColor.opacity(0.5) : Color.clear)
                                .frame(width: 6)
                                .contentShape(Rectangle())
                                .onHover { inside in
                                    if inside { NSCursor.resizeLeftRight.push() }
                                    else { NSCursor.pop() }
                                }
                                .gesture(
                                    DragGesture(coordinateSpace: .named("explorer"))
                                        .onChanged { value in
                                            isDraggingDivider = true
                                            splitFraction = min(max(value.location.x / geo.size.width, 0.25), 0.75)
                                        }
                                        .onEnded { _ in
                                            isDraggingDivider = false
                                        }
                                )
                        )

                    FilePane(side: .right)
                }
                .coordinateSpace(name: "explorer")
            }
        }
    }
}
