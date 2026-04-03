import SwiftUI

struct SettingsSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var pendingLocale: String = AppConstants.defaultLocale
    @State private var showRestartAlert = false
    @State private var showSetPassword = false

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

                    // 보안
                    GroupBox(L10n.t("lock.security")) {
                        VStack(alignment: .leading, spacing: 8) {
                            Toggle(L10n.t("lock.enable"), isOn: Bindable(appState.appLock).isEnabled)
                                .font(.system(size: 12))
                                .onChange(of: appState.appLock.isEnabled) {
                                    if appState.appLock.isEnabled && !appState.appLock.hasPassword() {
                                        showSetPassword = true
                                    }
                                    appState.appLock.saveConfig()
                                }

                            if appState.appLock.isEnabled {
                                if appState.appLock.canUseTouchID {
                                    Toggle(L10n.t("lock.useTouchID"), isOn: Bindable(appState.appLock).useTouchID)
                                        .font(.system(size: 12))
                                        .onChange(of: appState.appLock.useTouchID) {
                                            appState.appLock.saveConfig()
                                        }
                                }

                                HStack {
                                    Button(appState.appLock.hasPassword() ? L10n.t("lock.changePassword") : L10n.t("lock.setPassword")) {
                                        showSetPassword = true
                                    }
                                    .controlSize(.small)

                                    if appState.appLock.hasPassword() {
                                        Button(L10n.t("lock.removePassword"), role: .destructive) {
                                            appState.appLock.removePassword()
                                            appState.appLock.isEnabled = false
                                            appState.appLock.saveConfig()
                                        }
                                        .controlSize(.small)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }

                    // 성능
                    GroupBox(L10n.t("settings.performance")) {
                        VStack(spacing: 12) {
                            numberField(L10n.t("settings.transfers"), value: Bindable(appState.settings).transfers)
                            numberField(L10n.t("settings.checkers"), value: Bindable(appState.settings).checkers)
                            numberField(L10n.t("settings.multiThread"), value: Bindable(appState.settings).multiThreadStreams)
                            Text(L10n.t("settings.multiThreadHelp"))
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            stringField(L10n.t("settings.bufferSize"), value: Bindable(appState.settings).bufferSize, placeholder: "16M")
                            stringField(L10n.t("settings.bwLimit"), value: Bindable(appState.settings).bwLimit, placeholder: L10n.t("settings.disabled"))

                            // Bandwidth schedule
                            Toggle(L10n.t("settings.bwSchedule"), isOn: Bindable(appState.settings).bwScheduleEnabled)
                                .font(.system(size: 12))

                            if appState.settings.bwScheduleEnabled {
                                VStack(spacing: 4) {
                                    ForEach(Bindable(appState.settings).bwSchedule) { $entry in
                                        HStack(spacing: 4) {
                                            Picker("", selection: $entry.startHour) {
                                                ForEach(0..<24, id: \.self) { h in Text("\(h):00").tag(h) }
                                            }
                                            .frame(width: 70)
                                            Text("~")
                                            Picker("", selection: $entry.endHour) {
                                                ForEach(0..<24, id: \.self) { h in Text("\(h):00").tag(h) }
                                            }
                                            .frame(width: 70)
                                            TextField("rate", text: $entry.rate)
                                                .textFieldStyle(.roundedBorder)
                                                .frame(width: 70)
                                            Button(action: {
                                                appState.settings.bwSchedule.removeAll { $0.id == entry.id }
                                            }) {
                                                Image(systemName: "minus.circle").foregroundColor(.red)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                        .font(.system(size: 11))
                                    }
                                    Button(action: {
                                        appState.settings.bwSchedule.append(BwScheduleEntry())
                                    }) {
                                        Label(L10n.t("settings.addSchedule"), systemImage: "plus")
                                    }
                                    .controlSize(.small)
                                }
                            }
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
                    Task { await settings.applyToRclone() }
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
        .frame(width: 550, height: 650)
        .onDisappear {
            settings.saveToDisk()
        }
        .onAppear {
            pendingLocale = settings.locale
        }
        .onChange(of: pendingLocale) {
            if pendingLocale != settings.locale {
                showRestartAlert = true
            }
        }
        .sheet(isPresented: $showSetPassword) {
            SetPasswordSheet()
        }
        .alert(L10n.t("app.restart.title"), isPresented: $showRestartAlert) {
            Button(L10n.t("cancel")) { pendingLocale = settings.locale }
            Button(L10n.t("app.restart")) {
                settings.locale = pendingLocale
                settings.saveToDisk()
                // Relaunch: get the executable path and relaunch via shell
                let executableURL = Bundle.main.executableURL!
                let script = "sleep 0.5 && \"\(executableURL.path)\""
                let task = Process()
                task.executableURL = URL(fileURLWithPath: "/bin/sh")
                task.arguments = ["-c", script]
                try? task.run()
                exit(0)
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
