import SwiftUI

struct SettingsSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var pendingLocale: String = "ko"
    @State private var showRestartAlert = false

    private var settings: SettingsViewModel { appState.settings }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(L10n.t("settings.title"))
                    .font(.title2.bold())
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.system(size: 18))
                }
                .buttonStyle(.plain)
            }
            .padding()

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 언어
                    GroupBox(L10n.t("settings.language")) {
                        HStack {
                            Text(L10n.t("settings.appLanguage"))
                                .font(.system(size: 12))
                            Spacer()
                            Picker("", selection: $pendingLocale) {
                                Text("한국어").tag("ko")
                                Text("English").tag("en")
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 200)
                        }
                        .padding(.vertical, 4)
                    }

                    // 성능
                    GroupBox(L10n.t("settings.performance")) {
                        VStack(spacing: 12) {
                            numberField(L10n.t("settings.transfers"), value: Bindable(appState.settings).transfers)
                            numberField(L10n.t("settings.checkers"), value: Bindable(appState.settings).checkers)
                            numberField(L10n.t("settings.multiThread"), value: Bindable(appState.settings).multiThreadStreams)
                            stringField(L10n.t("settings.bufferSize"), value: Bindable(appState.settings).bufferSize, placeholder: "16M")
                            stringField(L10n.t("settings.bwLimit"), value: Bindable(appState.settings).bwLimit, placeholder: L10n.t("settings.disabled"))
                        }
                        .padding(.vertical, 4)
                    }

                    // 안정성
                    GroupBox(L10n.t("settings.reliability")) {
                        VStack(spacing: 12) {
                            numberField(L10n.t("settings.retries"), value: Bindable(appState.settings).retries)
                            numberField(L10n.t("settings.lowRetries"), value: Bindable(appState.settings).lowLevelRetries)
                            stringField(L10n.t("settings.connTimeout"), value: Bindable(appState.settings).contimeout, placeholder: "60s")
                            stringField(L10n.t("settings.ioTimeout"), value: Bindable(appState.settings).timeout, placeholder: "300s")
                        }
                        .padding(.vertical, 4)
                    }

                    // 동작
                    GroupBox(L10n.t("settings.behavior")) {
                        VStack(alignment: .leading, spacing: 8) {
                            stringField(L10n.t("settings.userAgent"), value: Bindable(appState.settings).userAgent, placeholder: L10n.t("settings.default"))
                            Toggle(L10n.t("settings.skipSSL"), isOn: Bindable(appState.settings).noCheckCertificate)
                                .font(.system(size: 12))
                            Toggle(L10n.t("settings.ignoreExist"), isOn: Bindable(appState.settings).ignoreExisting)
                                .font(.system(size: 12))
                            Toggle(L10n.t("settings.ignoreSize"), isOn: Bindable(appState.settings).ignoreSize)
                                .font(.system(size: 12))
                            Toggle(L10n.t("settings.noTraverse"), isOn: Bindable(appState.settings).noTraverse)
                                .font(.system(size: 12))
                            Toggle(L10n.t("settings.noModTime"), isOn: Bindable(appState.settings).noUpdateModTime)
                                .font(.system(size: 12))
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding()
            }

            Divider()

            HStack {
                Button(L10n.t("settings.resetDefaults")) {
                    settings.resetToDefaults()
                }

                Spacer()

                Button(L10n.t("cancel")) { dismiss() }
                    .keyboardShortcut(.cancelAction)

                Button(L10n.t("save")) {
                    settings.saveToDisk()
                    Task { await settings.applyToRclone() }
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
        .frame(width: 550, height: 650)
        .onAppear {
            pendingLocale = settings.locale
        }
        .onChange(of: pendingLocale) {
            if pendingLocale != settings.locale {
                showRestartAlert = true
            }
        }
        .alert(L10n.t("app.restart.title"), isPresented: $showRestartAlert) {
            Button(L10n.t("cancel")) { pendingLocale = settings.locale }
            Button(L10n.t("app.restart")) {
                settings.locale = pendingLocale
                settings.saveToDisk()
                // Relaunch
                let url = URL(fileURLWithPath: Bundle.main.resourcePath!)
                let path = url.deletingLastPathComponent().deletingLastPathComponent().absoluteString
                let task = Process()
                task.executableURL = URL(fileURLWithPath: "/usr/bin/open")
                task.arguments = [path]
                try? task.run()
                NSApplication.shared.terminate(nil)
            }
        } message: {
            Text(L10n.t("app.restart.message"))
        }
    }

    private func numberField(_ label: String, value: Binding<Int>) -> some View {
        HStack {
            Text(label).font(.system(size: 12))
            Spacer()
            TextField("", value: value, format: .number)
                .textFieldStyle(.roundedBorder)
                .frame(width: 80)
                .multilineTextAlignment(.trailing)
        }
    }

    private func stringField(_ label: String, value: Binding<String>, placeholder: String) -> some View {
        HStack {
            Text(label).font(.system(size: 12))
            Spacer()
            TextField(placeholder, text: value)
                .textFieldStyle(.roundedBorder)
                .frame(width: 120)
                .multilineTextAlignment(.trailing)
        }
    }
}
