import SwiftUI

struct SettingsSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    private var settings: SettingsViewModel { appState.settings }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("설정")
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
                    GroupBox("언어") {
                        HStack {
                            Text("앱 언어")
                                .font(.system(size: 12))
                            Spacer()
                            Picker("", selection: Bindable(appState.settings).locale) {
                                Text("한국어").tag("ko")
                                Text("English").tag("en")
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 200)
                        }
                        .padding(.vertical, 4)
                    }

                    // 성능
                    GroupBox("성능") {
                        VStack(spacing: 12) {
                            numberField("동시 전송 수 (Transfers)", value: Bindable(appState.settings).transfers)
                            numberField("동시 체크 수 (Checkers)", value: Bindable(appState.settings).checkers)
                            numberField("멀티스레드 스트림 (Multi-thread Streams)", value: Bindable(appState.settings).multiThreadStreams)
                            stringField("버퍼 크기 (Buffer Size)", value: Bindable(appState.settings).bufferSize, placeholder: "16M")
                            stringField("대역폭 제한 (Bandwidth Limit)", value: Bindable(appState.settings).bwLimit, placeholder: "비활성화")
                        }
                        .padding(.vertical, 4)
                    }

                    // 안정성
                    GroupBox("안정성") {
                        VStack(spacing: 12) {
                            numberField("재시도 횟수 (Retries)", value: Bindable(appState.settings).retries)
                            numberField("저수준 재시도 (Low-level Retries)", value: Bindable(appState.settings).lowLevelRetries)
                            stringField("연결 타임아웃 (Connect Timeout)", value: Bindable(appState.settings).contimeout, placeholder: "60s")
                            stringField("IO 타임아웃 (Timeout)", value: Bindable(appState.settings).timeout, placeholder: "300s")
                        }
                        .padding(.vertical, 4)
                    }

                    // 동작
                    GroupBox("동작") {
                        VStack(alignment: .leading, spacing: 8) {
                            stringField("User-Agent", value: Bindable(appState.settings).userAgent, placeholder: "기본값")
                            Toggle("SSL 인증서 검증 건너뛰기", isOn: Bindable(appState.settings).noCheckCertificate)
                                .font(.system(size: 12))
                            Toggle("기존 파일 무시 (Ignore Existing)", isOn: Bindable(appState.settings).ignoreExisting)
                                .font(.system(size: 12))
                            Toggle("크기 무시 (Ignore Size)", isOn: Bindable(appState.settings).ignoreSize)
                                .font(.system(size: 12))
                            Toggle("디렉토리 순회 건너뛰기 (No Traverse)", isOn: Bindable(appState.settings).noTraverse)
                                .font(.system(size: 12))
                            Toggle("수정시간 업데이트 안함 (No Update ModTime)", isOn: Bindable(appState.settings).noUpdateModTime)
                                .font(.system(size: 12))
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding()
            }

            Divider()

            HStack {
                Button("기본값 복원") {
                    settings.resetToDefaults()
                }

                Spacer()

                Button("취소") { dismiss() }
                    .keyboardShortcut(.cancelAction)

                Button("저장") {
                    settings.saveToDisk()
                    Task { await settings.applyToRclone() }
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
        .frame(width: 550, height: 650)
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
