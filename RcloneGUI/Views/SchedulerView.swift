import SwiftUI
import AppKit

struct SchedulerView: View {
    @Environment(AppState.self) private var appState
    @State private var showAddTask = false

    private var scheduler: SchedulerViewModel { appState.scheduler }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(L10n.t("scheduler.title")).font(.headline)
                Spacer()
                Button(action: { showAddTask = true }) {
                    Image(systemName: "plus")
                }
                .buttonStyle(.borderless)
            }
            .padding()

            Divider()

            if scheduler.tasks.isEmpty {
                ContentUnavailableView(L10n.t("scheduler.noTasks"), systemImage: "clock")
            } else {
                List {
                    ForEach(scheduler.tasks) { task in
                        HStack {
                            Toggle("", isOn: Binding(
                                get: { task.enabled },
                                set: { _ in scheduler.toggleTask(id: task.id) }
                            ))
                            .labelsHidden()

                            VStack(alignment: .leading, spacing: 2) {
                                Text(task.profileName).font(.body)
                                HStack(spacing: 8) {
                                    Text(task.intervalLabel)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    if let lastRun = task.lastRun {
                                        Text("\(L10n.t("scheduler.lastRun")): \(FormatUtils.formatDate(lastRun))")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }

                            Spacer()

                            Button(role: .destructive, action: { scheduler.removeTask(id: task.id) }) {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                }
                .listStyle(.inset)
            }

            Divider()

            VStack(spacing: 0) {
                HStack {
                    Text(L10n.t("scheduler.logs")).font(.subheadline).foregroundColor(.secondary)
                    Spacer()
                    Button(L10n.t("scheduler.exportLogs")) {
                        let panel = NSSavePanel()
                        panel.nameFieldStringValue = "scheduler-logs.txt"
                        panel.begin { result in
                            guard result == .OK, let url = panel.url else { return }
                            let text = scheduler.logs.joined(separator: "\n")
                            try? text.write(to: url, atomically: true, encoding: .utf8)
                        }
                    }
                    .controlSize(.small)
                    Button(L10n.t("scheduler.clearLogs")) {
                        scheduler.logs.removeAll()
                        scheduler.saveLogs()
                    }
                    .controlSize(.small)
                }
                .padding(.horizontal)
                .padding(.vertical, 6)

                if scheduler.logs.isEmpty {
                    Text(L10n.t("scheduler.noLogs"))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, minHeight: 60)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 2) {
                            ForEach(scheduler.logs, id: \.self) { log in
                                Text(log)
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(.primary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 4)
                    }
                    .frame(minHeight: 80, maxHeight: 160)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .sheet(isPresented: $showAddTask) {
            AddScheduleSheet()
        }
    }
}

struct AddScheduleSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var selectedProfileId: UUID?
    @State private var intervalMinutes: Int = 60

    var body: some View {
        VStack(spacing: 16) {
            Text(L10n.t("scheduler.addTask")).font(.headline)

            Form {
                Picker(L10n.t("sync.profiles"), selection: $selectedProfileId) {
                    Text("--").tag(UUID?.none)
                    ForEach(appState.sync.profiles) { profile in
                        Text(profile.name).tag(UUID?.some(profile.id))
                    }
                }

                HStack {
                    Text(L10n.t("scheduler.interval"))
                    Spacer()
                    TextField("", value: $intervalMinutes, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                    Text(L10n.t("scheduler.minutes"))
                }
            }
            .formStyle(.grouped)

            HStack {
                Button(L10n.t("cancel")) { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button(L10n.t("create")) {
                    guard let profileId = selectedProfileId,
                          let profile = appState.sync.profiles.first(where: { $0.id == profileId })
                    else { return }
                    let task = ScheduledTask(
                        profileId: profileId,
                        profileName: profile.name,
                        interval: TimeInterval(intervalMinutes * 60)
                    )
                    appState.scheduler.addTask(task)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(selectedProfileId == nil)
            }
        }
        .padding(20)
        .frame(width: 400)
    }
}
