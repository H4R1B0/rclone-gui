import SwiftUI

struct SetPasswordSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 16) {
            Text(L10n.t("lock.setPassword"))
                .font(.headline)

            SecureField(L10n.t("lock.password"), text: $password)
                .textFieldStyle(.roundedBorder)

            SecureField(L10n.t("lock.confirmPassword"), text: $confirmPassword)
                .textFieldStyle(.roundedBorder)

            if let error = errorMessage {
                Text(error).foregroundColor(.red).font(.caption)
            }

            HStack {
                Button(L10n.t("cancel")) { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button(L10n.t("save")) { save() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(password.isEmpty)
            }
        }
        .padding(20)
        .frame(width: 300)
    }

    private func save() {
        guard password == confirmPassword else {
            errorMessage = L10n.t("lock.passwordMismatch")
            return
        }
        guard password.count >= 4 else {
            errorMessage = L10n.t("lock.passwordTooShort")
            return
        }
        if appState.appLock.setPassword(password) {
            dismiss()
        } else {
            errorMessage = L10n.t("lock.passwordSaveFailed")
        }
    }
}
