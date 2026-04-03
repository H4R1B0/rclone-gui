import SwiftUI

struct OnboardingView: View {
    @Environment(AppState.self) private var appState
    @State private var step: Int = 0

    var body: some View {
        VStack(spacing: 0) {
            // Step indicator
            HStack(spacing: 8) {
                ForEach(0..<3) { i in
                    Capsule()
                        .fill(i <= step ? Color.accentColor : Color.secondary.opacity(0.2))
                        .frame(width: i == step ? 24 : 8, height: 4)
                        .animation(.easeInOut(duration: 0.2), value: step)
                }
            }
            .padding(.top, 24)

            Spacer()

            switch step {
            case 0:
                welcomeStep
            case 1:
                accountStep
            default:
                doneStep
            }

            Spacer()

            // Bottom navigation
            HStack {
                if step > 0 {
                    Button(action: { withAnimation { step -= 1 } }) {
                        Label(L10n.t("back"), systemImage: "chevron.left")
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
                }

                Spacer()

                if step < 2 {
                    Button(action: { withAnimation { skipToEnd() } }) {
                        Text(L10n.t("onboarding.skip"))
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Step 1: Welcome

    private var welcomeStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "cloud.fill")
                .font(.system(size: 56))
                .foregroundStyle(.linearGradient(
                    colors: [.blue, .purple],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))

            Text(AppConstants.appName)
                .font(.largeTitle.bold())

            Text(L10n.t("onboarding.subtitle"))
                .font(.title3)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 400)

            VStack(alignment: .leading, spacing: 14) {
                featureRow(icon: "rectangle.split.2x1", color: .blue,
                           text: L10n.t("onboarding.feature1"))
                featureRow(icon: "cloud.fill", color: .purple,
                           text: L10n.t("onboarding.feature2"))
                featureRow(icon: "lock.shield", color: .green,
                           text: L10n.t("onboarding.feature3"))
                featureRow(icon: "arrow.triangle.2.circlepath", color: .orange,
                           text: L10n.t("onboarding.feature4"))
            }
            .padding(.vertical, 8)

            Button(action: { withAnimation { step = 1 } }) {
                Text(L10n.t("onboarding.getStarted"))
                    .font(.headline)
                    .frame(width: 220)
            }
            .controlSize(.large)
            .buttonStyle(.borderedProminent)
        }
        .padding(.horizontal, 40)
    }

    // MARK: - Step 2: Add Account

    private var accountStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.badge.plus")
                .font(.system(size: 48))
                .foregroundColor(.accentColor)

            Text(L10n.t("account.title"))
                .font(.title2.bold())

            Text(L10n.t("onboarding.accountDesc"))
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 400)

            // Existing remotes
            if !appState.accounts.remotes.isEmpty {
                VStack(spacing: 6) {
                    ForEach(appState.accounts.remotes) { remote in
                        HStack(spacing: 10) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.system(size: 14))
                            Text(remote.displayName)
                                .font(.body)
                            Text(remote.type)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.green.opacity(0.06))
                        )
                    }
                }
                .frame(maxWidth: 400)
                .padding(.vertical, 4)
            }

            HStack(spacing: 12) {
                Button(action: { appState.showAccountSetup = true }) {
                    Label(L10n.t("account.add"), systemImage: "plus")
                        .frame(width: 180)
                }
                .controlSize(.large)
                .buttonStyle(.borderedProminent)

                Button(action: { withAnimation { step = 2 } }) {
                    Text(L10n.t("onboarding.next"))
                        .frame(width: 100)
                }
                .controlSize(.large)
                .buttonStyle(.bordered)
            }
        }
        .padding(.horizontal, 40)
        .sheet(isPresented: Bindable(appState).showAccountSetup) {
            AccountSetupView()
                .frame(minWidth: 650, minHeight: 550)
        }
    }

    // MARK: - Step 3: Done

    private var doneStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundColor(.green)

            Text(L10n.t("onboarding.ready"))
                .font(.title2.bold())

            Text(L10n.t("onboarding.readyDesc"))
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 400)

            Button(action: {
                appState.onboardingComplete = true
                UserDefaults.standard.set(true, forKey: "onboardingComplete")
            }) {
                Text(L10n.t("onboarding.start"))
                    .font(.headline)
                    .frame(width: 220)
            }
            .controlSize(.large)
            .buttonStyle(.borderedProminent)
        }
        .padding(.horizontal, 40)
    }

    // MARK: - Helpers

    private func featureRow(icon: String, color: Color, text: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
                .frame(width: 28, height: 28)
            Text(text)
                .font(.body)
        }
    }

    private func skipToEnd() {
        step = 2
    }
}
