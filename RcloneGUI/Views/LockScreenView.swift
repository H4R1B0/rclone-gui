import SwiftUI

struct LockScreenView: View {
    @Environment(AppState.self) private var appState
    @State private var password = ""
    @State private var shake = false
    @State private var unlocking = false

    private var lock: AppLockViewModel { appState.appLock }

    var body: some View {
        ZStack {
            // Background
            Color(nsColor: .windowBackgroundColor)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // Lock icon
                Image(systemName: unlocking ? "lock.open.fill" : "lock.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.accentColor)
                    .animation(.easeInOut, value: unlocking)

                Text("Rclone GUI")
                    .font(.title2.bold())

                // Password field
                VStack(spacing: 8) {
                    SecureField(L10n.t("lock.password"), text: $password)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 250)
                        .onSubmit { verifyPassword() }
                        .offset(x: shake ? -10 : 0)
                        .animation(.default.repeatCount(3, autoreverses: true).speed(6), value: shake)

                    if let error = lock.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }

                HStack(spacing: 12) {
                    Button(L10n.t("lock.unlock")) { verifyPassword() }
                        .keyboardShortcut(.defaultAction)
                        .disabled(password.isEmpty)

                    if lock.canUseTouchID && lock.useTouchID {
                        Button(action: { Task { await lock.promptTouchID() } }) {
                            Image(systemName: "touchid")
                                .font(.system(size: 24))
                        }
                        .buttonStyle(.plain)
                        .help("Touch ID")
                    }
                }
            }
        }
        .task {
            // Auto-prompt Touch ID on appear
            if lock.canUseTouchID && lock.useTouchID {
                _ = await lock.promptTouchID()
            }
        }
    }

    private func verifyPassword() {
        if lock.verifyPassword(password) {
            unlocking = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                lock.unlock()
            }
        } else {
            lock.errorMessage = L10n.t("lock.wrongPassword")
            shake.toggle()
            password = ""
        }
    }
}
