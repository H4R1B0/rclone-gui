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
                    Text("검색어를 입력하고 Enter를 누르세요")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            if search.hasSearched {
                HStack {
                    Text("\(search.results.count)개 결과")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if search.isSearching {
                        ProgressView().controlSize(.mini)
                        Text("검색 중...")
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
                TextField("파일 검색...", text: Bindable(appState.search).query)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { Task { await search.performSearch() } }

                if search.isSearching {
                    Button("취소") { search.abortSearch() }
                        .controlSize(.small)
                } else {
                    Button("검색") { Task { await search.performSearch() } }
                        .controlSize(.small)
                        .disabled(search.query.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    cloudToggle("/", label: "로컬")
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
                Text("이름").frame(maxWidth: .infinity, alignment: .leading)
                Text("클라우드").frame(width: 100, alignment: .leading)
                Text("크기").frame(width: 80, alignment: .trailing)
                Text("수정일").frame(width: 140, alignment: .trailing)
                Text("경로").frame(width: 200, alignment: .leading)
            }
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(.secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(Color(nsColor: .controlBackgroundColor))

            Divider()

            if search.results.isEmpty && !search.isSearching {
                Text("검색 결과가 없습니다")
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
                Text(result.remoteFs == "/" ? "로컬" : result.remoteFs.replacingOccurrences(of: ":", with: ""))
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
