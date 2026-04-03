import SwiftUI

struct ErrorBannerView: View {
    let classified: ClassifiedError
    var onAction: (() -> Void)?
    var onDismiss: (() -> Void)?

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: iconName)
                .foregroundColor(iconColor)
                .font(.system(size: 14))

            VStack(alignment: .leading, spacing: 2) {
                Text(classified.userMessage)
                    .font(.system(size: 12, weight: .medium))
                Text(classified.suggestion)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }

            Spacer()

            if let actionLabel = classified.actionLabel, let onAction = onAction {
                Button(actionLabel) { onAction() }
                    .controlSize(.small)
            }

            if let onDismiss = onDismiss {
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(backgroundColor)
        .cornerRadius(8)
    }

    private var iconName: String {
        switch classified.severity {
        case .info: return "info.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .error: return "xmark.circle.fill"
        case .critical: return "exclamationmark.octagon.fill"
        }
    }

    private var iconColor: Color {
        switch classified.severity {
        case .info: return .blue
        case .warning: return .orange
        case .error: return .red
        case .critical: return .red
        }
    }

    private var backgroundColor: Color {
        switch classified.severity {
        case .info: return .blue.opacity(0.1)
        case .warning: return .orange.opacity(0.1)
        case .error: return .red.opacity(0.1)
        case .critical: return .red.opacity(0.15)
        }
    }
}
