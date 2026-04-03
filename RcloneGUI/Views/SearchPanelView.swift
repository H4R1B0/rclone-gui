import SwiftUI
import RcloneKit

struct SearchPanelView: View {
    @Environment(AppState.self) private var appState

    private var search: SearchViewModel { appState.search }

    @State private var filterType: String = ""
    @State private var filterMinSize: String = ""
    @State private var filterMaxSize: String = ""
    @State private var filterDateFrom: Date = Calendar.current.date(byAdding: .year, value: -10, to: Date())!
    @State private var filterDateTo: Date = Date()
    @State private var filterDateEnabled: Bool = false
    @State private var filterPath: String = ""

    private var filteredResults: [SearchResult] {
        search.results.filter { result in
            if !filterType.isEmpty {
                let icon = FormatUtils.fileIcon(name: result.name, isDir: result.isDir)
                let typeMatch: Bool
                switch filterType {
                case "image": typeMatch = icon == "photo"
                case "video": typeMatch = icon == "film"
                case "audio": typeMatch = icon == "music.note"
                case "doc": typeMatch = icon == "doc.text" || icon == "doc.richtext"
                case "archive": typeMatch = icon == "doc.zipper"
                default: typeMatch = true
                }
                if !typeMatch { return false }
            }
            if let min = Int64(filterMinSize), result.size < min * 1024 { return false }
            if let max = Int64(filterMaxSize), result.size > max * 1024 { return false }
            if filterDateEnabled {
                if result.modTime < filterDateFrom || result.modTime > filterDateTo {
                    return false
                }
            }
            if !filterPath.isEmpty {
                if !result.path.localizedCaseInsensitiveContains(filterPath) {
                    return false
                }
            }
            return true
        }
    }

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
                    Text(String(format: L10n.t("search.results"), filteredResults.count))
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
                    ForEach(appState.panels.remotes, id: \.self) { remote in
                        cloudToggle("\(remote):", label: remote)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 4)
            }

            HStack(spacing: 8) {
                Picker(L10n.t("search.filterType"), selection: $filterType) {
                    Text(L10n.t("search.allTypes")).tag("")
                    Text(L10n.t("search.images")).tag("image")
                    Text(L10n.t("search.videos")).tag("video")
                    Text(L10n.t("search.audio")).tag("audio")
                    Text(L10n.t("search.documents")).tag("doc")
                    Text(L10n.t("search.archives")).tag("archive")
                }
                .frame(width: 150)

                TextField(L10n.t("search.minSize"), text: $filterMinSize)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 80)
                Text("~")
                TextField(L10n.t("search.maxSize"), text: $filterMaxSize)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 80)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 4)

            HStack(spacing: 8) {
                Toggle(L10n.t("search.dateFilter"), isOn: $filterDateEnabled)
                    .font(.system(size: 11))
                    .frame(width: 100)

                if filterDateEnabled {
                    DatePicker("", selection: $filterDateFrom, displayedComponents: .date)
                        .frame(width: 110)
                        .labelsHidden()
                    Text("~")
                    DatePicker("", selection: $filterDateTo, displayedComponents: .date)
                        .frame(width: 110)
                        .labelsHidden()
                }

                Spacer()

                TextField(L10n.t("search.pathFilter"), text: $filterPath)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 150)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 4)
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

            if filteredResults.isEmpty && !search.isSearching {
                Text(L10n.t("search.noResults"))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(filteredResults) { result in
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
