import SwiftUI
import RcloneKit

struct SearchPanelView: View {
    @Environment(AppState.self) private var appState

    private var search: SearchViewModel { appState.search }

    var body: some View {
        VStack(spacing: 0) {
            searchHeader

            Divider()

            if search.isSearching || search.hasSearched {
                resultsTable
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text(L10n.t("search.hint"))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            if search.hasSearched {
                HStack {
                    Text(String(format: L10n.t("search.results"), search.results.count))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if search.isSearching {
                        ProgressView().controlSize(.mini)
                        Text(L10n.t("search.searching"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Color(nsColor: .controlBackgroundColor))
            }
        }
    }

    // MARK: - Search Header

    private var searchHeader: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField(L10n.t("search.placeholder"), text: Bindable(appState.search).query)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { Task { await search.performSearch() } }

                if search.isSearching {
                    Button(L10n.t("search.cancel")) { search.abortSearch() }
                        .controlSize(.small)
                } else {
                    Button(L10n.t("search.button")) { Task { await search.performSearch() } }
                        .controlSize(.small)
                        .disabled(search.query.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    cloudToggle("/", label: L10n.t("panel.local"))
                    ForEach(appState.panels.remotes, id: \.self) { remote in
                        cloudToggle("\(remote):", label: remote)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
            }
        }
    }

    private func cloudToggle(_ cloud: String, label: String) -> some View {
        Button(action: { search.toggleCloud(cloud) }) {
            HStack(spacing: 4) {
                Image(systemName: cloud == "/" ? "folder" : "cloud")
                    .font(.system(size: 10))
                Text(label)
                    .font(.system(size: 11))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(search.selectedClouds.contains(cloud) ? Color.accentColor.opacity(0.2) : Color(nsColor: .controlBackgroundColor))
            .cornerRadius(4)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Results Table

    private var resultsTable: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Text(L10n.t("column.name")).frame(maxWidth: .infinity, alignment: .leading)
                Text(L10n.t("search.cloud")).frame(width: 100, alignment: .leading)
                Text(L10n.t("column.size")).frame(width: 80, alignment: .trailing)
                Text(L10n.t("column.modified")).frame(width: 140, alignment: .trailing)
                Text(L10n.t("properties.path")).frame(width: 200, alignment: .leading)
            }
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(.secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(Color(nsColor: .controlBackgroundColor))

            Divider()

            if search.results.isEmpty && !search.isSearching {
                Text(L10n.t("search.noResults"))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(search.results) { result in
                            resultRow(result)
                        }
                    }
                }
            }
        }
    }

    private func resultRow(_ result: SearchResult) -> some View {
        HStack(spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: FormatUtils.fileIcon(name: result.name, isDir: result.isDir))
                    .font(.system(size: 12))
                    .foregroundColor(result.isDir ? .accentColor : .secondary)
                Text(result.name)
                    .font(.system(size: 12))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 4) {
                Image(systemName: result.remoteFs == "/" ? "folder" : "cloud")
                    .font(.system(size: 10))
                Text(result.remoteFs == "/" ? L10n.t("panel.local") : result.remoteFs.replacingOccurrences(of: ":", with: ""))
                    .font(.system(size: 11))
            }
            .frame(width: 100, alignment: .leading)

            Text(result.isDir ? "-" : FormatUtils.formatBytes(result.size))
                .font(.system(size: 11))
                .monospacedDigit()
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .trailing)

            Text(FormatUtils.formatDate(result.modTime))
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .frame(width: 140, alignment: .trailing)

            Text(PathUtils.parent(result.path))
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(width: 200, alignment: .leading)
                .help(result.path)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 3)
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            if result.isDir {
                Task {
                    await appState.panels.navigateTo(side: .right, remote: result.remoteFs, path: result.path)
                    appState.activeView = .explore
                }
            }
        }
    }
}
