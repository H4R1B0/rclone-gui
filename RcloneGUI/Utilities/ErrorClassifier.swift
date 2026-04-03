import Foundation

struct ClassifiedError {
    let originalMessage: String
    let userMessage: String
    let suggestion: String
    let actionLabel: String?
    let severity: Severity

    enum Severity {
        case info, warning, error, critical
    }
}

enum ErrorClassifier {
    static func classify(_ error: String) -> ClassifiedError {
        let lower = error.lowercased()

        // Auth / Permission
        if lower.contains("token") || lower.contains("oauth") || lower.contains("401") || lower.contains("403") || lower.contains("unauthorized") {
            return ClassifiedError(
                originalMessage: error,
                userMessage: L10n.t("error.authFailed"),
                suggestion: L10n.t("error.authSuggestion"),
                actionLabel: L10n.t("error.reauth"),
                severity: .error
            )
        }

        // Quota / Space
        if lower.contains("quota") || lower.contains("space") || lower.contains("storage") || lower.contains("413") || lower.contains("insufficient") {
            return ClassifiedError(
                originalMessage: error,
                userMessage: L10n.t("error.quotaFull"),
                suggestion: L10n.t("error.quotaSuggestion"),
                actionLabel: nil,
                severity: .warning
            )
        }

        // Network
        if lower.contains("network") || lower.contains("timeout") || lower.contains("connection") || lower.contains("unreachable") || lower.contains("dns") {
            return ClassifiedError(
                originalMessage: error,
                userMessage: L10n.t("error.network"),
                suggestion: L10n.t("error.networkSuggestion"),
                actionLabel: L10n.t("retry"),
                severity: .warning
            )
        }

        // Not found
        if lower.contains("not found") || lower.contains("404") || lower.contains("no such") {
            return ClassifiedError(
                originalMessage: error,
                userMessage: L10n.t("error.notFound"),
                suggestion: L10n.t("error.notFoundSuggestion"),
                actionLabel: nil,
                severity: .warning
            )
        }

        // Rate limit
        if lower.contains("rate") || lower.contains("429") || lower.contains("too many") {
            return ClassifiedError(
                originalMessage: error,
                userMessage: L10n.t("error.rateLimit"),
                suggestion: L10n.t("error.rateLimitSuggestion"),
                actionLabel: nil,
                severity: .info
            )
        }

        // Conflict
        if lower.contains("conflict") || lower.contains("already exists") {
            return ClassifiedError(
                originalMessage: error,
                userMessage: L10n.t("error.conflict"),
                suggestion: L10n.t("error.conflictSuggestion"),
                actionLabel: nil,
                severity: .warning
            )
        }

        // Default
        return ClassifiedError(
            originalMessage: error,
            userMessage: error,
            suggestion: L10n.t("error.genericSuggestion"),
            actionLabel: nil,
            severity: .error
        )
    }
}
