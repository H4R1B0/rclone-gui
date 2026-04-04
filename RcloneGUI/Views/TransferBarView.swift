import SwiftUI
import RcloneKit

extension View {
    @ViewBuilder
    func transferLabelStyle(mode: TransferDisplayMode) -> some View {
        switch mode {
        case .iconOnly:
            self.labelStyle(.iconOnly)
        case .textOnly:
            self.labelStyle(.titleOnly)
        case .iconAndText:
            self.labelStyle(.titleAndIcon)
        }
    }

    func quickTooltip(_ text: String, delay: Double = 0.3) -> some View {
        self.modifier(QuickTooltipModifier(text: text, delay: delay))
    }
}

struct QuickTooltipModifier: ViewModifier {
    let text: String
    let delay: Double

    @State private var isHovering = false
    @State private var showTooltip = false
    @State private var hoverTask: Task<Void, Never>?

    func body(content: Content) -> some View {
        content
            .onHover { hovering in
                isHovering = hovering
                hoverTask?.cancel()
                if hovering {
                    hoverTask = Task {
                        try? await Task.sleep(for: .seconds(delay))
                        guard !Task.isCancelled else { return }
                        showTooltip = true
                    }
                } else {
                    showTooltip = false
                }
            }
            .overlay(alignment: .bottom) {
                if showTooltip {
                    Text(text)
                        .font(.system(size: 11))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(nsColor: .windowBackgroundColor))
                                .shadow(color: .black.opacity(0.2), radius: 3, y: 1)
                        )
                        .fixedSize()
                        .offset(y: 28)
                        .transition(.opacity)
                        .zIndex(999)
                        .allowsHitTesting(false)
                }
            }
            .animation(.easeInOut(duration: 0.15), value: showTooltip)
    }
}

struct TransferBarView: View {
    @Environment(AppState.self) private var appState
    @State private var showReport = false
    @State private var showErrorPopover = false

    private var isExpanded: Bool { appState.showTransfers }

    var body: some View {
        VStack(spacing: 0) {
            if isExpanded {
                expandedView
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
                    .padding(.bottom, 4)
            }

            // Compact status bar — always visible
            compactBar
        }
    }

    // MARK: - Compact Bar

    private var compactBar: some View {
        HStack(spacing: 10) {
            if appState.transfers.hasActiveTransfers {
                Circle()
                    .fill(appState.transfers.paused ? Color.orange : Color.green)
                    .frame(width: 6, height: 6)

                ProgressView(value: overallProgress)
                    .frame(width: 100)

                Text("\(appState.transfers.transfers.count) \(L10n.t("menubar.activeTransfers"))")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)

                Text(FormatUtils.formatSpeed(appState.transfers.totalSpeed))
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(.accentColor)

                if appState.transfers.paused {
                    Text(L10n.t("transfer.paused"))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.orange)
                }
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.system(size: 10))
                Text(L10n.t("menubar.noTransfers"))
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Error badge
            if appState.transfers.errors > 0 {
                Button(action: { showErrorPopover = true }) {
                    HStack(spacing: 3) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                            .font(.system(size: 9))
                        Text("\(appState.transfers.errors)")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.red)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(4)
                }
                .buttonStyle(.plain)
                .popover(isPresented: $showErrorPopover) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(L10n.t("transfer.errorDetails"))
                            .font(.system(size: 12, weight: .semibold))
                        Divider()
                        if appState.transfers.lastErrors.isEmpty {
                            Text(L10n.t("transfer.noErrors"))
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        } else {
                            ScrollView {
                                VStack(alignment: .leading, spacing: 4) {
                                    ForEach(appState.transfers.lastErrors, id: \.self) { err in
                                        Text(err)
                                            .font(.system(size: 11, design: .monospaced))
                                            .textSelection(.enabled)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                }
                            }
                            .frame(maxHeight: 200)
                        }
                    }
                    .padding(12)
                    .frame(minWidth: 300)
                }
            }

            // Completed count (when collapsed)
            if !appState.transfers.completed.isEmpty && !isExpanded {
                Text("\(appState.transfers.completed.count) \(L10n.t("transfer.completed"))")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }

            Button(action: { withAnimation(.easeInOut(duration: 0.2)) { appState.showTransfers.toggle() } }) {
                Image(systemName: isExpanded ? "chevron.down" : "chevron.up")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.secondary)
                    .frame(width: 20, height: 20)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help(L10n.t("toolbar.transfers"))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(.bar)
    }

    // MARK: - Expanded View (card style)

    private var expandedView: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 8) {
                Text(L10n.t("toolbar.transfers"))
                    .font(.system(size: 12, weight: .semibold))

                if appState.transfers.hasActiveTransfers {
                    Text("\(appState.transfers.transfers.count)")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 1)
                        .background(Capsule().fill(Color.accentColor))
                }

                Spacer()

                if appState.transfers.hasActiveTransfers {
                    HStack(spacing: 4) {
                        // Merged pause/resume toggle button
                        Button(action: {
                            Task {
                                if appState.transfers.paused {
                                    await appState.transfers.resumeAll()
                                } else {
                                    await appState.transfers.pauseAll()
                                }
                            }
                        }) {
                            Label(
                                appState.transfers.paused ? L10n.t("transfer.resume") : L10n.t("transfer.pause"),
                                systemImage: appState.transfers.paused ? "play.fill" : "pause.fill"
                            )
                            .font(.system(size: 10))
                        }
                        .transferLabelStyle(mode: appState.settings.transferDisplayMode)
                        .controlSize(.small)
                        .buttonStyle(.bordered)
                        .quickTooltip(appState.transfers.paused ? L10n.t("transfer.resume") : L10n.t("transfer.pause"))

                        // Stop all button
                        Button(action: { Task { await appState.transfers.stopAllJobs() } }) {
                            Label(L10n.t("transfer.stopAll"), systemImage: "stop.fill")
                                .font(.system(size: 10))
                        }
                        .transferLabelStyle(mode: appState.settings.transferDisplayMode)
                        .controlSize(.small)
                        .buttonStyle(.bordered)
                        .quickTooltip(L10n.t("transfer.stopAll"))
                    }
                }

                Button(action: { showReport = true }) {
                    Label(L10n.t("report.title"), systemImage: "doc.text")
                        .font(.system(size: 10))
                }
                .transferLabelStyle(mode: appState.settings.transferDisplayMode)
                .controlSize(.mini)
                .quickTooltip(L10n.t("report.title"))

                if appState.transfers.hasInactiveItems {
                    Button(action: { appState.transfers.clearInactive() }) {
                        Label(L10n.t("transfer.clearInactive"), systemImage: "xmark.bin")
                            .font(.system(size: 10))
                    }
                    .transferLabelStyle(mode: appState.settings.transferDisplayMode)
                    .controlSize(.mini)
                    .quickTooltip(L10n.t("transfer.clearInactive"))
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .contextMenu {
                ForEach(TransferDisplayMode.allCases, id: \.self) { mode in
                    Button(action: {
                        appState.settings.transferDisplayMode = mode
                        appState.settings.scheduleSave()
                    }) {
                        HStack {
                            Text(mode.label)
                            if appState.settings.transferDisplayMode == mode {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }

            Divider().padding(.horizontal, 8)

            // Transfer list
            ScrollView {
                LazyVStack(spacing: 2) {
                    // Active transfers (count already shown in header badge)
                    ForEach(appState.transfers.transfers) { t in
                        activeTransferRow(t)
                    }

                    // Section: Queued (waiting for slot)
                    if !appState.transfers.queued.isEmpty {
                        sectionHeader(L10n.t("transfer.section.queued"), count: appState.transfers.queued.count)
                        ForEach(appState.transfers.queued) { q in
                            queuedTransferRow(q)
                        }
                    }

                    // Section: Completed (successful)
                    if !appState.transfers.successfulCompleted.isEmpty {
                        sectionHeader(L10n.t("transfer.section.completed"), count: appState.transfers.successfulCompleted.count)
                        ForEach(appState.transfers.successfulCompleted.prefix(30)) { t in
                            completedTransferRow(t)
                        }
                    }

                    // Section: Failed
                    if !appState.transfers.errorCompleted.isEmpty {
                        sectionHeader(L10n.t("transfer.section.failed"), count: appState.transfers.errorCompleted.count)
                        ForEach(appState.transfers.errorCompleted.prefix(30)) { t in
                            completedTransferRow(t)
                        }
                    }

                    // Section: Stopped transfers
                    if !appState.transfers.stopped.isEmpty {
                        sectionHeader(L10n.t("transfer.section.stopped"), count: appState.transfers.stopped.count)
                        ForEach(appState.transfers.stopped) { t in
                            stoppedTransferRow(t)
                        }
                    }

                    // Section: Checkpoints (retry waiting)
                    if !appState.transfers.checkpoints.isEmpty {
                        sectionHeader(L10n.t("transfer.section.retryWaiting"), count: appState.transfers.checkpoints.count)
                        ForEach(appState.transfers.checkpoints) { cp in
                            checkpointRow(cp)
                        }
                    }

                    if appState.transfers.transfers.isEmpty
                        && appState.transfers.queued.isEmpty
                        && appState.transfers.completed.isEmpty
                        && appState.transfers.stopped.isEmpty
                        && appState.transfers.checkpoints.isEmpty {
                        VStack(spacing: 6) {
                            Image(systemName: "arrow.up.arrow.down.circle")
                                .font(.system(size: 24))
                                .foregroundColor(.secondary.opacity(0.4))
                            Text(L10n.t("menubar.noTransfers"))
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 30)
                    }
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 6)
            }
        }
        .frame(height: 250)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(Color(nsColor: .separatorColor).opacity(0.5), lineWidth: 0.5)
        )
        .sheet(isPresented: $showReport) {
            TransferReportSheet()
        }
    }

    // MARK: - Row Views

    private func queuedTransferRow(_ q: QueuedTransfer) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "clock.fill")
                .font(.system(size: 10))
                .foregroundColor(.secondary.opacity(0.6))

            Image(systemName: q.isDir ? "folder.fill" : "doc.fill")
                .font(.system(size: 9))
                .foregroundColor(.secondary.opacity(0.5))

            Text(q.name)
                .font(.system(size: 11))
                .lineLimit(1)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(L10n.t("transfer.queued"))
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.orange)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(3)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
    }

    private func sectionHeader(_ title: String, count: Int) -> some View {
        HStack {
            Text("\(title) (\(count))")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.top, 6)
        .padding(.bottom, 2)
    }

    private func activeTransferRow(_ t: RcloneTransferring) -> some View {
        VStack(spacing: 4) {
            // Row 1: file name + speed + stop button
            HStack(spacing: 6) {
                Image(systemName: "doc.fill")
                    .font(.system(size: 9))
                    .foregroundColor(.accentColor.opacity(0.7))

                Text(t.name)
                    .font(.system(size: 11))
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if t.size > 0 {
                    Text("\(FormatUtils.formatBytes(t.bytes))/\(FormatUtils.formatBytes(t.size))")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(.secondary)
                }

                Text(FormatUtils.formatSpeed(t.speed))
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundColor(.secondary)

                Button(action: {
                    Task {
                        let group = t.group
                        let transfers = appState.transfers
                        if let jobId = transfers.jobIds.first(where: { "\($0)" == group || group == "job/\($0)" }) {
                            await transfers.stopJob(id: jobId)
                        } else {
                            await transfers.stopAllJobs()
                        }
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary.opacity(0.6))
                }
                .buttonStyle(.plain)
                .quickTooltip(L10n.t("transfer.stop"))
            }

            // Row 2: progress bar + percentage
            HStack(spacing: 6) {
                ProgressView(value: Double(t.percentage), total: 100)
                    .tint(.accentColor)

                Text("\(t.percentage)%")
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .foregroundColor(.accentColor)
                    .frame(width: 32, alignment: .trailing)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.accentColor.opacity(0.05))
        )
        .contextMenu {
            Button(role: .destructive, action: {
                Task {
                    let group = t.group
                    let transfers = appState.transfers
                    if let jobId = transfers.jobIds.first(where: { "\($0)" == group || group == "job/\($0)" }) {
                        await transfers.stopJob(id: jobId)
                    } else {
                        await transfers.stopAllJobs()
                    }
                }
            }) {
                Label(L10n.t("transfer.stopThis"), systemImage: "stop.circle")
            }
        }
    }

    private func completedTransferRow(_ t: RcloneCompletedTransfer) -> some View {
        HStack(spacing: 10) {
            Image(systemName: t.ok ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(t.ok ? .green : .red)
                .font(.system(size: 11))

            Text(t.name)
                .font(.system(size: 11))
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(FormatUtils.formatBytes(t.size))
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.secondary)
                .frame(width: 70, alignment: .trailing)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .contextMenu {
            if !t.ok {
                if appState.transfers.copyOrigins[t.group] != nil || appState.transfers.copyOrigins[t.name] != nil {
                    Button(action: {
                        if let origin = appState.transfers.copyOrigins[t.group] ?? appState.transfers.copyOrigins[t.name] {
                            let cp = TransferCheckpoint(
                                fileName: t.name,
                                srcFs: origin.srcFs, srcRemote: origin.srcRemote,
                                dstFs: origin.dstFs, dstRemote: origin.dstRemote,
                                isDir: origin.isDir, totalSize: t.size
                            )
                            Task { await appState.transfers.retryCheckpoint(cp) }
                        }
                    }) {
                        Label(L10n.t("transfer.restart"), systemImage: "arrow.clockwise")
                    }
                }
            }
            Button(role: .destructive, action: {
                appState.transfers.removeCompleted(name: t.name, completedAt: t.completed_at)
            }) {
                Label(L10n.t("transfer.remove"), systemImage: "trash")
            }
        }
    }

    private func stoppedTransferRow(_ t: StoppedTransfer) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "stop.circle.fill")
                .foregroundColor(.orange)
                .font(.system(size: 11))

            Text(t.name)
                .font(.system(size: 11))
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            if t.size > 0 {
                Text(FormatUtils.formatBytes(t.size))
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondary)
                    .frame(width: 70, alignment: .trailing)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.orange.opacity(0.04))
        )
        .contextMenu {
            if t.srcFs != nil {
                Button(action: { Task { await appState.transfers.restartTransfer(t) } }) {
                    Label(L10n.t("transfer.restart"), systemImage: "arrow.clockwise")
                }
            }
            Button(role: .destructive, action: { appState.transfers.removeStopped(id: t.id) }) {
                Label(L10n.t("transfer.remove"), systemImage: "trash")
            }
        }
    }

    private func checkpointRow(_ cp: TransferCheckpoint) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "arrow.clockwise.circle.fill")
                .foregroundColor(.orange)
                .font(.system(size: 11))

            VStack(alignment: .leading, spacing: 1) {
                Text(cp.fileName)
                    .font(.system(size: 11))
                    .lineLimit(1)
                if let error = cp.lastError {
                    Text(error)
                        .font(.system(size: 9))
                        .foregroundColor(.red)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text("\(cp.attempts)/\(AppConstants.maxTransferRetries)")
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(.secondary)

            if cp.attempts < AppConstants.maxTransferRetries {
                Button(L10n.t("transfer.restart")) {
                    Task { await appState.transfers.retryCheckpoint(cp) }
                }
                .controlSize(.mini)
            }

            Button(action: { appState.transfers.removeCheckpoint(id: cp.id) }) {
                Image(systemName: "xmark")
                    .font(.system(size: 8))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.orange.opacity(0.06))
        )
        .contextMenu {
            if cp.attempts < AppConstants.maxTransferRetries {
                Button(action: { Task { await appState.transfers.retryCheckpoint(cp) } }) {
                    Label(L10n.t("transfer.restart"), systemImage: "arrow.clockwise")
                }
            }
            Button(role: .destructive, action: { appState.transfers.removeCheckpoint(id: cp.id) }) {
                Label(L10n.t("transfer.remove"), systemImage: "trash")
            }
        }
    }

    // MARK: - Helpers

    private var overallProgress: Double {
        guard appState.transfers.totalSize > 0 else { return 0 }
        return min(Double(appState.transfers.totalBytes) / Double(appState.transfers.totalSize), 1.0)
    }
}
