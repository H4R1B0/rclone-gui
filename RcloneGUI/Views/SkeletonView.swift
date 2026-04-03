import SwiftUI
// MARK: - Shimmer Effect

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [.clear, .white.opacity(0.3), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: phase * 200)
            )
            .clipped()
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

// MARK: - Skeleton Primitives

struct SkeletonRect: View {
    var width: CGFloat? = nil
    var height: CGFloat = 12
    var cornerRadius: CGFloat = 4

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color(nsColor: .separatorColor).opacity(0.3))
            .frame(width: width, height: height)
            .shimmer()
    }
}

struct SkeletonCircle: View {
    var size: CGFloat = 20

    var body: some View {
        Circle()
            .fill(Color(nsColor: .separatorColor).opacity(0.3))
            .frame(width: size, height: size)
            .shimmer()
    }
}

// MARK: - File List Skeleton

struct FileListSkeleton: View {
    var rowCount: Int = 8

    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<rowCount, id: \.self) { i in
                HStack(spacing: 10) {
                    SkeletonRect(width: 16, height: 16, cornerRadius: 3)
                    SkeletonRect(width: CGFloat.random(in: 80...200), height: 12)
                    Spacer()
                    SkeletonRect(width: 50, height: 10)
                    SkeletonRect(width: 90, height: 10)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .opacity(1.0 - Double(i) * 0.08)

                if i < rowCount - 1 {
                    Divider().padding(.leading, 38)
                }
            }
            Spacer()
        }
    }
}

// MARK: - Remote Card Grid Skeleton

struct RemoteGridSkeleton: View {
    var cardCount: Int = 4

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(0..<cardCount, id: \.self) { i in
                VStack(spacing: 8) {
                    SkeletonCircle(size: 24)
                    SkeletonRect(width: 80, height: 12)
                    SkeletonRect(width: 50, height: 10)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
                .cornerRadius(8)
                .opacity(1.0 - Double(i) * 0.1)
            }
        }
        .padding(20)
    }
}

// MARK: - Detail Info Skeleton

struct DetailSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack(spacing: 12) {
                SkeletonCircle(size: 32)
                VStack(alignment: .leading, spacing: 6) {
                    SkeletonRect(width: 140, height: 16)
                    SkeletonRect(width: 80, height: 10)
                }
                Spacer()
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(10)

            // Quota
            GroupBox {
                VStack(alignment: .leading, spacing: 8) {
                    SkeletonRect(height: 6, cornerRadius: 3)
                    HStack {
                        SkeletonRect(width: 100, height: 10)
                        Spacer()
                        SkeletonRect(width: 100, height: 10)
                    }
                }
            }

            // Config
            GroupBox {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(0..<4, id: \.self) { i in
                        HStack {
                            SkeletonRect(width: 80, height: 10)
                            SkeletonRect(width: CGFloat.random(in: 100...180), height: 10)
                            Spacer()
                        }
                        .opacity(1.0 - Double(i) * 0.1)
                    }
                }
            }
        }
        .padding(20)
    }
}

// MARK: - Mount List Skeleton

struct MountListSkeleton: View {
    var rowCount: Int = 3

    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<rowCount, id: \.self) { i in
                HStack(spacing: 10) {
                    SkeletonRect(width: 20, height: 20, cornerRadius: 4)
                    VStack(alignment: .leading, spacing: 4) {
                        SkeletonRect(width: 120, height: 12)
                        SkeletonRect(width: 180, height: 10)
                    }
                    Spacer()
                    SkeletonRect(width: 60, height: 22, cornerRadius: 6)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .opacity(1.0 - Double(i) * 0.15)
            }
            Spacer()
        }
    }
}

// MARK: - Search Results Skeleton

struct SearchResultsSkeleton: View {
    var rowCount: Int = 6

    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<rowCount, id: \.self) { i in
                HStack(spacing: 0) {
                    HStack(spacing: 6) {
                        SkeletonRect(width: 14, height: 14, cornerRadius: 3)
                        SkeletonRect(width: CGFloat.random(in: 80...160), height: 11)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    SkeletonRect(width: 60, height: 10)
                        .frame(width: 100, alignment: .leading)
                    SkeletonRect(width: 40, height: 10)
                        .frame(width: 80, alignment: .trailing)
                    SkeletonRect(width: 70, height: 10)
                        .frame(width: 140, alignment: .trailing)
                    SkeletonRect(width: 100, height: 10)
                        .frame(width: 200, alignment: .leading)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .opacity(1.0 - Double(i) * 0.1)
            }
            Spacer()
        }
    }
}

// MARK: - Version History Skeleton

struct VersionListSkeleton: View {
    var rowCount: Int = 3

    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<rowCount, id: \.self) { i in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        SkeletonRect(width: 140, height: 12)
                        SkeletonRect(width: 100, height: 8)
                    }
                    Spacer()
                    SkeletonRect(width: 60, height: 10)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .opacity(1.0 - Double(i) * 0.15)
            }
            Spacer()
        }
    }
}

// MARK: - App Startup Skeleton

struct AppStartupSkeleton: View {
    var body: some View {
        HStack(spacing: 0) {
            // Sidebar skeleton
            VStack(alignment: .leading, spacing: 0) {
                SkeletonRect(width: 100, height: 12)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 8)

                ForEach(0..<2, id: \.self) { _ in
                    HStack(spacing: 8) {
                        SkeletonRect(width: 14, height: 14, cornerRadius: 3)
                        SkeletonRect(width: 80, height: 11)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                }

                SkeletonRect(width: 80, height: 12)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 8)

                ForEach(0..<3, id: \.self) { i in
                    HStack(spacing: 8) {
                        SkeletonCircle(size: 14)
                        SkeletonRect(width: CGFloat.random(in: 60...120), height: 11)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .opacity(1.0 - Double(i) * 0.15)
                }

                Spacer()
            }
            .frame(width: 220)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))

            Divider()

            // Content skeleton
            VStack(spacing: 0) {
                // Tab bar
                HStack {
                    SkeletonRect(width: 80, height: 20, cornerRadius: 6)
                    Spacer()
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial)

                // Path bar
                HStack(spacing: 4) {
                    SkeletonRect(width: 16, height: 16, cornerRadius: 3)
                    SkeletonRect(width: 60, height: 12)
                    SkeletonRect(width: 8, height: 12)
                    SkeletonRect(width: 80, height: 12)
                    Spacer()
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)

                Divider()

                FileListSkeleton()
            }
        }
    }
}

// MARK: - Error Retry View

struct ErrorRetryView: View {
    let message: String
    var detail: String? = nil
    var onRetry: (() -> Void)?

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 32))
                .foregroundColor(.orange)

            Text(message)
                .font(.system(size: 13, weight: .medium))
                .multilineTextAlignment(.center)

            if let detail = detail {
                Text(detail)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 300)
            }

            if let onRetry = onRetry {
                Button(action: onRetry) {
                    Label(L10n.t("retry"), systemImage: "arrow.clockwise")
                }
                .controlSize(.regular)
                .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
