import SwiftUI

struct OnboardingView: View {
    @Environment(AppState.self) private var appState
    @State private var step: OnboardingStep = .welcome

    enum OnboardingStep {
        case welcome
        case addAccount
        case done
    }

    var body: some View {
        VStack(spacing: 0) {
            switch step {
            case .welcome:
                welcomeStep
            case .addAccount:
                AccountSetupView()
                    .overlay(alignment: .topLeading) {
                        Button(action: { step = .done }) {
                            Label(L10n.t("onboarding.skip"), systemImage: "forward")
                                .font(.caption)
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.secondary)
                        .padding()
                    }
            case .done:
                doneStep
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var welcomeStep: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "cloud.fill")
                .font(.system(size: 64))
                .foregroundStyle(.linearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))

            Text("RcloneGUI")
                .font(.largeTitle.bold())

            Text(L10n.t("onboarding.subtitle"))
                .font(.title3)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: 12) {
                featureRow(icon: "rectangle.split.2x1", text: L10n.t("onboarding.feature1"))
                featureRow(icon: "cloud.fill", text: L10n.t("onboarding.feature2"))
                featureRow(icon: "lock.shield", text: L10n.t("onboarding.feature3"))
                featureRow(icon: "arrow.triangle.2.circlepath", text: L10n.t("onboarding.feature4"))
            }
            .padding(.vertical, 16)

            Button(action: { step = .addAccount }) {
                Text(L10n.t("onboarding.getStarted"))
                    .font(.headline)
                    .frame(width: 200)
            }
            .controlSize(.large)
            .buttonStyle(.borderedProminent)

            Button(L10n.t("onboarding.skip")) {
                step = .done
            }
            .font(.caption)
            .foregroundColor(.secondary)

            Spacer()
        }
        .padding(40)
    }

    private var doneStep: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundColor(.green)

            Text(L10n.t("onboarding.ready"))
                .font(.title2.bold())

            Text(L10n.t("onboarding.readyDesc"))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button(action: {
                appState.onboardingComplete = true
                UserDefaults.standard.set(true, forKey: "onboardingComplete")
            }) {
                Text(L10n.t("onboarding.start"))
                    .font(.headline)
                    .frame(width: 200)
            }
            .controlSize(.large)
            .buttonStyle(.borderedProminent)

            Spacer()
        }
        .padding(40)
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.accentColor)
                .frame(width: 30)
            Text(text)
                .font(.body)
        }
    }
}
